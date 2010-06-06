require "optparse"
require "ostruct"

module UrlInjector
  class << self
    def parse_options( argv )
      collected_options = OpenStruct.new

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: url-injector [options]"
        opts.separator ""
        opts.separator "Specific options:"
        
        opts.on("-u", "--url-file FILE", String, "Required. Path to FILE containing a list of URLs to scan, one per line") do |file|
          collected_options.url_file = file
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
      
      if not collected_options.url_file
        puts "missing required option: --url-file"
        puts
        puts opts
        return
      end

      collected_options
    end
  end
end
