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
        puts "repeating each url #{options.repeat} times" if options.repeat > 1
      end
      
      if options.bail then
        puts "--bail invoked, terminating"
        exit
      end
      
      require "core/sqs-interface.rb"
      
      url_results = []

      consecutive_sleeps = 0
      loop do

        if cmd = AWS::SQS::command?
          Adbot::output_json( url_results, options ) if cmd == AWS::SQS::PROCESS_MATCHES
          abort "received shutdown command" if cmd == AWS::SQS::SHUTDOWN
        end
        
        begin
          url_message = AWS::SQS::next_url
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

        options.repeat.times do |i|
          url_result = Adbot::scan_url( url_message.to_s, options )

          if not url_result or url_result.error_scanning
            puts "scan failed for url #{url_message.to_s}" if options.verbose
            break
          end

          url_results << url_result
          #Adbot::save_url( url_result, options )

          puts "done run #{i+1} of #{options.repeat} for #{url_message.to_s}" if options.verbose and options.repeat > 1
        end
        
        AWS::SQS::done_with_next_url url_message
      end
    end # def run
  end # class << self
end # AdBot
