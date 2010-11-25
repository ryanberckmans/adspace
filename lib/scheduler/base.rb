require "core/util.rb"
require "core/coroutine.rb"
require Util.here "commandline-options.rb"

module Scheduler
  INTERVAL = 60 * 0.5
  DESIRED_INTERVALS = 4
  NEW_RATE_RATIO = 0.5
  MINIMUM_QUEUE_SIZE = 20

  def self.consumption_tracker( coroutine )
    previous_size = 0
    consumption_rate = 0.0
    while true
      previous_size = AWS::SQS::size rescue previous_size
      coroutine.yield
      size = AWS::SQS::size rescue previous_size
      puts previous_size
      puts size
      consumption_rate = consumption_rate * NEW_RATE_RATIO + (previous_size - size) * (1 - NEW_RATE_RATIO)
      puts "consumption_rate: #{consumption_rate}"
      increase_queue_by = DESIRED_INTERVALS * [consumption_rate,0.0].max - size
      coroutine.yield [increase_queue_by.to_i,0,MINIMUM_QUEUE_SIZE - size].max
    end
  end

  def self.domains_with_no_scans( scan_ids, new_scans )
    added = 0
    domains = (Domain.find :all).select { |d| d.scans.size < 1 }
    domains.each do |domain|
      scan_id = 0 #Scan.schedule domain, path
      puts "#{domain.url} had no scans, scheduled scan with id #{scan_id}"
      added += 1
      scan_ids << scan_id
    end
    added
  end

  def self.domains_another_scan( scan_ids, new_scans )
    0
  end

  def self.domains_failed( scan_ids, new_scans )
    0
  end

  def self.add_new_domains( new_scans )

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
      scan_id = 0 #Scan.schedule u.domain, u.path
      puts "scheduled #{url} with scan id #{scan_id}"
      scan_ids << scan_id
      sleep 0.15 # don't hit sqs so hard. they can handle it but we crash sometimes
    end
    inject scan_ids
  end

  def self.run
    options = Scheduler::parse_options ARGV

    $SQS_QUEUE = options.sqs_queue
    puts "using sqs queue #{$SQS_QUEUE}" if $SQS_QUEUE
    require "core/sqs-interface.rb"

    manual_urls options.urls

    consumption = Coroutine.new { |cr| consumption_tracker cr }
    
    while true
      consumption.resume
      sleep INTERVAL
      new_scans = consumption.resume

      scan_ids = []
      puts "new scans #{new_scans}"
      while new_scans > 0
        new_scans -= domains_with_no_scans scan_ids, new_scans
        new_scans -= domains_another_scan scan_ids, new_scans
        new_scans -= domains_failed scan_ids, new_scans
        add_new_domains new_scans
        break
      end
      inject scan_ids
    end
  end
end
