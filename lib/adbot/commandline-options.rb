require "optparse"
require "ostruct"

module Adbot

  class << self

    def parse_options( argv )
      collected_options = OpenStruct.new
      
      collected_options.repeat = 1
      collected_options.selenium_host = "localhost"
      collected_options.selenium_port = 4444
      collected_options.human_client = "no-client"
      
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: scanner [options]"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-a", "--advertisers-file FILE", String, "Optional. Path to FILE containing advertisers to scan each web page for, one per line (each complete line is an advertiser which is scanned for)") do |file|
          collected_options.scan_file = file
        end
        
        opts.on("-r", "--repeat-num-times INT", Integer, "Optional. Integer specifying how many times to repeat the scanning process for each url (default 1)") do |repeat|
          collected_options.repeat = repeat
        end
        
        opts.on("--selenium-host HOST", String, "Optional. Ip address or domain of selenium server (default localhost)") do |host|
          collected_options.selenium_host = host
        end

        opts.on("--selenium-port PORT", String, "Optional. Port of selenium server (default 4444)") do |port|
          collected_options.selenium_port = port
        end

        
        opts.on("-c", "--client CLIENT", String, "Optional. The human customer the scan is being performed for (default no-client)") do |client|
          collected_options.human_client = client
        end    
        
        opts.on("-v", "--verbose", "Optional. Verbose mode") do
          collected_options.verbose = true
        end
        
        opts.on("-b", "--bail", "Optional. Set everything up but exit instead of connecting to selenium server") do
          collected_options.bail = true
        end
        
        opts.on_tail("-h", "--help", "Show this message") do
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
