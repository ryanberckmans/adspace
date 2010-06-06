require "core/util.rb"
require File.here "commandline-options.rb"
require File.here "load-data.rb"
require File.here "scan.rb"
require File.here "process-matches.rb"

module Adbot

  POLL_FREQUENCY = 20 # seconds
  
  class << self
    
    def run
      
      options = Adbot::parse_options( ARGV )
      
      abort unless options
      
      scans = AdBot::get_scans options.scan_file
      
      if options.verbose then
        puts "this scan being performed for client: " + options.human_client
        
        puts "selenium server host: " + options.selenium_host
        puts "selenium server port: 4444"
        
        puts "repeating each url #{options.repeat} times"
        
        puts "competitors to be sought (found #{scans.length}):"
        scans.each { |scan| puts " " + scan }
      end
      
      if options.bail then
        puts "--bail invoked, terminating"
        exit
      end
      
      require "core/sqs-interface.rb"
      
      scans_with_match = {}
      
      loop do

        Adbot::process_matches( scans_with_match, options ) if AWS::SQS::process_matches?
        
        begin
          url_message = AWS::SQS::next_url
        rescue Exception => e
          url_message = nil
        end
        
        sleep POLL_FREQUENCY and next unless url_message
        
        Adbot::scan_url( url_message.to_s, scans, options, scans_with_match )
        
        AWS::SQS::done_with_next_url url_message
      end
    end # def run
  end # class << self
end # AdBot
