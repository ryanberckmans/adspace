require "core/log.rb"
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

      Log::info "selenium server host: #{options.selenium_host}"
      Log::info "selenium server port: #{options.selenium_port}"
      Log::info "output directory: #{options.output_dir}"
      Log::info "not following ads" unless options.follow_ads

      if options.bail then
        Log::info "--bail invoked, terminating"
        exit
      end

      $SQS_QUEUE = options.sqs_queue if options.sqs_queue
      Log::info "using sqs queue #{$SQS_QUEUE}" if $SQS_QUEUE
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
          Log::info "sleeping for #{time} seconds", "adbot"
          sleep time and next
        else
          consecutive_sleeps = 0
        end

        url_result = Adbot::scan_url scan_id.to_s, options

        if not url_result
          Log::info "scan failed scan_id #{scan_id.to_s}", "adbot"
        elsif url_result.exception
          Log::info "scan failed for #{url_result.domain + url_result.path} scan_id #{scan_id.to_s}", "adbot"
        else
          Log::info "scan succeeded for #{url_result.domain + url_result.path} scan_id #{scan_id.to_s}", "adbot"
        end

        begin
          Adbot::save url_result, scan_id.to_s if url_result # not ::save clobbers the url_result struct
        rescue Exception => e
          Log::error e.backtrace.join "\t"
          Log::error e.message
          Log::error "#{e.class} failed to save scan #{scan_id.to_s} to db", "adbot"
        end

        AWS::SQS::done_with_next scan_id
      end # loop do
    end # def run
  end # class << self
end # AdBot
