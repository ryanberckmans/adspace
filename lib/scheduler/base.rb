require "core/log.rb"
require "core/util.rb"
require "core/coroutine.rb"
require Util.here "commandline-options.rb"

module Scheduler
  INTERVAL = 60 * 1
  DESIRED_INTERVALS = 3
  NEW_RATE_RATIO = 0.5
  MINIMUM_QUEUE_SIZE = 25
  HOUR = 60 * 60
  DAY = HOUR * 24
  WEEK = DAY * 7
  RESCAN_NO_ADS = WEEK
  RESCAN_HAS_ADS = DAY * 3
  RESCAN_FAIL = WEEK

  def self.consumption_tracker( coroutine )
    size = AWS::SQS::size rescue 0
    Log::info "initial queue size #{size}", "scheduler"
    previous_size = 0
    consumption_rate_per_minute = 0.0
    increase_queue_by = 0
    time_previous = Time.now
    while true
      previous_size = size + increase_queue_by
      coroutine.yield
      size = AWS::SQS::size rescue previous_size
      time_now = Time.now
      elapsed_minutes = (time_now - time_previous) / 60.0
      consumption_rate_per_minute = consumption_rate_per_minute * NEW_RATE_RATIO + ( (previous_size - size) / elapsed_minutes ) * (1 - NEW_RATE_RATIO)
      rate_increase = (DESIRED_INTERVALS * [consumption_rate_per_minute,0.0].max - size).to_i
      increase_queue_by = [rate_increase,0,MINIMUM_QUEUE_SIZE - size].max
      Log::info "consumption per minute: #{"%.2f" % consumption_rate_per_minute}, time elapsed: #{"%.2f" % (time_now - time_previous)}s, previous queue: #{previous_size}, queue: #{size}, increase by: #{increase_queue_by}", "scheduler"
      time_previous = time_now
      coroutine.yield increase_queue_by
    end
  end

  def self.never_scanned( scan_ids, max_size )
    return unless scan_ids.size < max_size
    domains = Domain.find :all, :conditions => ["scans.id IS NULL"], :joins => ["left join scans on domains.id = scans.domain_id"]
    domains.each do |domain|
      break unless scan_ids.size < max_size
      scan_id = Scan.schedule domain.url, "/"
      Log::info "scheduled #{scan_id}, #{domain.url} has never been scanned", "scheduler"
      scan_ids << scan_id
    end
  end

  def self.inflight( scan_ids, max_size )
    return unless scan_ids.size < max_size
    uncompleted = Scan.find :all, :limit => max_size - scan_ids.size, :conditions => [ "scan_completed = ? and updated_at < ?", false, Time.now - HOUR * 6  ]
    uncompleted.each do |scan|
      break unless scan_ids.size < max_size
      scan.touch
      Log::info "scheduled #{scan.id}, this scan was never completed", "scheduler"
      scan_ids << scan.id
    end
  end

  def self.rescan( scan_ids, max_size )
    return unless scan_ids.size < max_size
    scans = Scan.find :all, :order => "updated_at DESC", :group => [ :path, :domain_id ]
    new_scan_time = {}
    scans.each do |scan|
      if scan.scan_fail
        new_scan_time[ scan.id ] = scan.updated_at + RESCAN_FAIL
      elsif scan.ads.size > 0
        new_scan_time[ scan.id ] = scan.updated_at + RESCAN_HAS_ADS
      else
        new_scan_time[ scan.id ] = scan.updated_at + RESCAN_NO_ADS
      end
    end
    
    (scans.sort_by { |s| new_scan_time[s.id] }).each do |scan|
      break unless scan_ids.size < max_size
      next unless scan.scan_completed
      if new_scan_time[scan.id] < Time.now
        scan_id = Scan.schedule scan.domain.url, scan.path
        Log::info "scheduled #{scan_id}, #{scan.domain.url}#{scan.path} rescan (#{scan.ads.size} ads, last #{scan.updated_at}, next #{new_scan_time[scan.id]})", "scheduler"
        scan_ids << scan_id
      end
    end
  end

  def self.new_domains( max )
    return unless max > 0
    
    search_min = 0
    search_max = $quantcast_order.size
    while true
      Log::debug "domain binary search, search min #{search_min} search max #{search_max}", "scheduler"
      search_mid = (search_min + search_max) / 2
      if Domain.find_by_url("http://" + $quantcast_order[ search_mid ] )
        Log::debug "domain at #{search_mid}", "scheduler"
        search_min = search_mid + 1
      else
        Log::debug "nil at #{search_mid}", "scheduler"
        search_max = search_mid - 1
      end
      break if search_max - search_min < 2
    end # this binary search algorithm bounds the number of database calls to find the next un-registered domain with lowest quantcast_rank
    Log::debug "new domain binary search terminated at #{search_min}", "scheduler"
    
    quantcast_index = search_min
    while max > 0
      raw_domain = $quantcast_order [ quantcast_index ]
      domain = "http://" + raw_domain
      if Domain.find_by_url domain
        # domain already exists
      else
        quantcast_rank = $quantcast_ranks[ raw_domain ]
        Domain.create({ :url => domain, :quantcast_rank => quantcast_rank })
        Log::info "registered domain #{domain} #{quantcast_rank}", "scheduler"
        max -= 1
      end
      quantcast_index += 1
    end
  end

  def self.inject( scan_ids )
    scan_ids.each do |scan_id|
      AWS::SQS::push scan_id
      Log::debug "injected scan_id #{scan_id}", "scheduler"
    end
  end

  def self.manual_urls( urls )
    Log::info "manually scheduling urls:", "scheduler" if urls.length > 0
    scan_ids = []
    urls.each do |url|
      u = Util::decompose_url url
      if not u
        Log::debug "skipped #{url}", "scheduler"
        next
      end
      scan_id = Scan.schedule u.domain, u.path
      Log::info "scheduled #{url} with scan id #{scan_id}", "scheduler"
      scan_ids << scan_id
    end
    inject scan_ids
  end

  def self.run( options )
    $SQS_QUEUE = options.sqs_queue
    Log::info "using sqs queue #{$SQS_QUEUE}" if $SQS_QUEUE
    require "core/sqs-interface.rb"

    manual_urls options.urls

    puts "queue size: #{AWS::SQS::size}" if options.size

    if options.clear
      AWS::SQS::clear rescue nil
      msg = "queue cleared"
      msg += " #{$SQS_QUEUE}" if $SQS_QUEUE
      puts msg
    end

    exit if options.bail

    if options.interval
      Scheduler.send :remove_const, :INTERVAL
      Scheduler.send :const_set, :INTERVAL, options.interval.to_i
    end
    Log::info "interval set to #{INTERVAL} seconds", "scheduler"

    Util::init_quantcast

    consumption = Coroutine.new { |cr| consumption_tracker cr }
    
    while true
      consumption.resume
      Log::info "sleeping (#{INTERVAL})", "scheduler"
      sleep INTERVAL
      max_size = consumption.resume

      scan_ids = []
      Log::debug "entering main loop", "scheduler"
      while scan_ids.size < max_size
        Log::debug "entering inflight", "scheduler"
        inflight scan_ids, max_size
        Log::debug "exiting inflight (#{scan_ids.size} of #{max_size} scans allocated)", "scheduler"
        Log::debug "entering never_scanned", "scheduler"
        never_scanned scan_ids, max_size
        Log::debug "exiting never_scanned (#{scan_ids.size} of #{max_size} scans allocated)", "scheduler"
        Log::debug "entering rescan", "scheduler"
        rescan scan_ids, max_size
        Log::debug "exiting rescan (#{scan_ids.size} of #{max_size} scans allocated)", "scheduler"
        Log::debug "entering new_domains", "scheduler"
        new_domains max_size - scan_ids.size
        Log::debug "exiting new_domains (#{scan_ids.size} of #{max_size} scans allocated)", "scheduler"
      end
      Log::debug "exiting main loop", "scheduler"
      inject scan_ids
      Log::info "#{scan_ids.size} (max #{max_size}) added to the queue", "scheduler"
    end
  end
end
