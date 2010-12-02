require "core/util.rb"
require Util.here "commandline-options.rb"
require Util.here "scan.rb"
require Util.here "process-matches.rb"
require Util.here "database.rb"

module Adbot

  BASE_POLL_FREQUENCY = 2 # seconds
  MAX_BACKOFF = 4 # adbot will not sleep longer than BASE_POLL_FREQUENCY * 2**MAX_BACKOFF
  
  class << self

    def sleep_time( consecutive_sleeps )
      BASE_POLL_FREQUENCY * 2 ** consecutive_sleeps
    end
    
    def run( options )
      
      abort unless options

      if options.verbose then
        puts "selenium server host: #{options.selenium_host}"
        puts "selenium server port: #{options.selenium_port}"
        puts "output directory: #{options.output_dir}"
        puts "not following ads" unless options.follow_ads
      end
      
      if options.bail then
        puts "--bail invoked, terminating"
        exit
      end

      $SQS_QUEUE = options.sqs_queue if options.sqs_queue
      puts "using sqs queue #{$SQS_QUEUE}" if $SQS_QUEUE
      require "core/sqs-interface.rb"
      
      consecutive_sleeps = 0

      loop do
        begin
          scan_id = AWS::SQS::next
        rescue Interrupt, SystemExit
          raise
        rescue Exception => e
          scan_id = nil
        end

        if not scan_id
          time = sleep_time consecutive_sleeps
          consecutive_sleeps += 1 unless consecutive_sleeps == MAX_BACKOFF
          puts "sleeping for #{time} seconds" if options.verbose
          sleep time and next
        else
          consecutive_sleeps = 0
        end

        url_result = Adbot::scan_url scan_id.to_s, options

        if not url_result
          puts "scan failed scan_id #{scan_id.to_s}"
        elsif url_result.exception
          puts "scan failed for #{url_result.domain + url_result.path} scan_id #{scan_id.to_s}"
        else
          puts "scan succeeded for #{url_result.domain + url_result.path} scan_id #{scan_id.to_s}"
        end

        begin
          Adbot::save url_result, scan_id.to_s if url_result # not ::save clobbers the url_result struct
        rescue Exception => e
          puts e.backtrace
          puts e.message
          puts "failed to save scan #{scan_id.to_s} to db"
        end

        AWS::SQS::done_with_next scan_id
      end # loop do
    end # def run
  end # class << self
end # AdBot
