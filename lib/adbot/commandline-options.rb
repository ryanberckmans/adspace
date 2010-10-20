require "optparse"
require "ostruct"

module Adbot

  class << self

    def parse_options( argv )
      collected_options = OpenStruct.new

      collected_options.follow_ads = true
      collected_options.output_dir = "/tmp/"
      collected_options.selenium_host = "localhost"
      collected_options.selenium_port = 4444
      collected_options.sqs_queue = nil
      
      opts = OptionParser.new do |opts|
        opts.banner = "usage: scanner [options]"
        opts.separator ""
        opts.separator "specific options:"

        opts.on("-o", "--output-directory DIR", String, "optional. output scan data to DIR (default /tmp)") do |dir|
          collected_options.output_dir = dir
        end

        opts.on("-n", "--no-follow-ads", "optional. don't follow advertisements by clicking on them") do
          collected_options.follow_ads = false
        end

        opts.on("--sqs QUEUE", String, "optional. use QUEUE instead of the default sqs queue") do |queue|
          collected_options.sqs_queue = queue
        end
        
        opts.on("--selenium-host HOST", String, "optional. ip address or domain of selenium server (default localhost)") do |host|
          collected_options.selenium_host = host
        end

        opts.on("--selenium-port PORT", String, "optional. port of selenium server (default 4444)") do |port|
          collected_options.selenium_port = port
        end

        opts.on("-v", "--verbose", "optional. verbose mode") do
          collected_options.verbose = true
        end
        
        opts.on("-b", "--bail", "optional. read commandline options but exit instead of running adbot") do
          collected_options.bail = true
        end
        
        opts.on_tail("-h", "--help", "show this message") do
          puts opts
          exit
        end
      end
      
      begin 
        opts.parse!(argv)
      rescue OptionParser::ParseError => e
        puts e.message
        puts
        puts opts
        return
      end
      
      collected_options
    end
  end # class << self
end # module AdBot
