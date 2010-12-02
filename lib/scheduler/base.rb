require "core/util.rb"
require "core/coroutine.rb"
require Util.here "commandline-options.rb"

module Scheduler
  INTERVAL = 60 * 1
  DESIRED_INTERVALS = 10
  NEW_RATE_RATIO = 0.35
  MINIMUM_QUEUE_SIZE = 12
  HOUR = 60 * 60
  DAY = HOUR * 24
  WEEK = DAY * 7
  RESCAN_NO_ADS = WEEK
  RESCAN_HAS_ADS = DAY * 2
  RESCAN_FAIL = WEEK

  def self.consumption_tracker( coroutine )
    previous_size = 0
    consumption_rate = 0.0
    while true
      previous_size = AWS::SQS::size rescue previous_size
      coroutine.yield
      size = AWS::SQS::size rescue previous_size
      consumption_rate = consumption_rate * NEW_RATE_RATIO + (previous_size - size) * (1 - NEW_RATE_RATIO)
      puts "consumption_rate: #{consumption_rate}, queue size: #{size}"
      increase_queue_by = DESIRED_INTERVALS * [consumption_rate,0.0].max - size
      coroutine.yield [increase_queue_by.to_i,0,MINIMUM_QUEUE_SIZE - size].max
    end
  end

  def self.never_scanned( scan_ids, max_size )
    return unless scan_ids.size < max_size
    domains = (Domain.find :all).select { |d| d.scans.size < 1 }
    domains.each do |domain|
      break unless scan_ids.size < max_size
      scan_id = Scan.schedule domain.url, "/"
      puts "scheduled #{scan_id}, #{domain.url} has never been scanned"
      scan_ids << scan_id
    end
  end

  def self.inflight( scan_ids, max_size )
    return unless scan_ids.size < max_size
    uncompleted = Scan.find :all, :conditions => [ "scan_completed = ? and updated_at < ?", false, Time.now - HOUR * 6  ]
    uncompleted.each do |scan|
      break unless scan_ids.size < max_size
      scan.touch
      puts "scheduled #{scan.id}, this scan was never completed"
      scan_ids << scan.id
    end
  end

  def self.rescan( scan_ids, max_size )
    return unless scan_ids.size < max_size
    scans = Scan.find :all, :order => "updated_at DESC", :group => [ :path, :domain_id ], :conditions => [ "scan_completed = ? ", true ]
    (scans.sort_by { |s| s.updated_at }).each do |scan|
      break unless scan_ids.size < max_size
      next_scan = scan.updated_at
      if scan.scan_fail
        next_scan += RESCAN_FAIL
      elsif scan.ads.size > 0
        next_scan += RESCAN_HAS_ADS
      else
        next_scan += RESCAN_NO_ADS
      end
      if next_scan < Time.now
        scan_id = Scan.schedule scan.domain.url, scan.path
        puts "scheduled #{scan_id}, #{scan.domain.url}#{scan.path} rescan (#{scan.ads.size} ads, last #{scan.updated_at})"
        scan_ids << scan_id
      end
    end
  end

  def self.new_domains( max )
    quantcast_rank = 1
    while max > 0
      domain = "http://" + $quantcast_ranks.index( quantcast_rank.to_s )
      if Domain.find_by_url domain
        # domain already exists
      else
        Domain.create({ :url => domain, :quantcast_rank => quantcast_rank })
        puts "registered domain #{domain} #{quantcast_rank}"
        max -= 1
      end
      quantcast_rank += 1
    end
  end

  def self.inject( scan_ids )
    scan_ids.each do |scan_id|
      AWS::SQS::push scan_id
      puts "injected scan_id #{scan_id}"
    end
  end

  def self.manual_urls( urls )
    puts "manually scheduling urls:" if urls.length > 0
    scan_ids = []
    urls.each do |url|
      u = Util::decompose_url url
      if not u
        puts "skipped #{url}"
        next
      end
      scan_id = Scan.schedule u.domain, u.path
      puts "scheduled #{url} with scan id #{scan_id}"
      scan_ids << scan_id
    end
    inject scan_ids
  end

  def self.run
    options = Scheduler::parse_options ARGV

    $SQS_QUEUE = options.sqs_queue
    puts "using sqs queue #{$SQS_QUEUE}" if $SQS_QUEUE
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

    Util::init_quantcast

    consumption = Coroutine.new { |cr| consumption_tracker cr }
    
    while true
      consumption.resume
      puts "sleeping\n---------------------"
      sleep INTERVAL
      max_size = consumption.resume

      scan_ids = []
      puts "queue requires additional #{max_size}"
      while scan_ids.size < max_size
        inflight scan_ids, max_size
        never_scanned scan_ids, max_size
        rescan scan_ids, max_size
        new_domains max_size - scan_ids.size
      end
      inject scan_ids
      puts "#{scan_ids.size} (max #{max_size}) added to the queue"
    end
  end
end
