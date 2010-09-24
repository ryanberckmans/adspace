require "optparse"
require "ostruct"

module UrlInjector
  class << self
    def parse_options( argv )
      collected_options = OpenStruct.new

      collected_options.size = false
      collected_options.repeat = 1
      collected_options.urls = []

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: url-injector [options]"
        opts.separator ""
        opts.separator "Specific options:"
        
        opts.on("-u", "--url-file FILE", String, "Optional. Path to FILE containing a list of URLs to inject, one per line") do |file|
          collected_options.url_file = file
        end

        opts.on("--url URL", String, "Optional. Inject URL. Use --url any number of times. Each URL must be prefixed with transport protocol (i.e. http://)") do |url|
          collected_options.urls.push url
        end

        opts.on("-s", "--size", "optional. return the current size of the url queue and then exit") do
          collected_options.size = true
        end

        opts.on("-r", "--repeat-num-times INT", Integer, "Optional. Integer specifying how many times to inject each url (default 1)") do |repeat|
          collected_options.repeat = repeat
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
  end
end
