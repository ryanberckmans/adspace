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
    
    def run
      options = Adbot::parse_options( ARGV )
      
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
          url_message = AWS::SQS::next_url
        rescue Interrupt, SystemExit
          raise
        rescue Exception => e
          url_message = nil
        end

        if not url_message
          time = sleep_time consecutive_sleeps
          consecutive_sleeps += 1 unless consecutive_sleeps == MAX_BACKOFF
          puts "sleeping for #{time} seconds" if options.verbose
          sleep time and next
        else
          consecutive_sleeps = 0
        end

        url_result = Adbot::scan_url( url_message.to_s, options )

        puts "scan failed for url #{url_message.to_s}" if (not url_result or url_result.exception)
        
        begin
          Adbot::save url_result if url_result
        rescue Exception => e
          puts e.backtrace
          puts e.message
          puts "failed to save scan to db"
        end

        AWS::SQS::done_with_next_url url_message
      end # loop do
    end # def run
  end # class << self
end # AdBot
