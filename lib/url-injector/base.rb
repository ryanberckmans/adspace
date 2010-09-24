require "core/util.rb"
require Util.here "commandline-options.rb"
require Util.here "load-data.rb"

module UrlInjector
  class << self
    def run
      options = UrlInjector::parse_options( ARGV )

      abort unless options

      options.urls += get_urls( options.url_file ) if options.url_file

      if options.verbose then
        puts "urls to be injected into scanner (found #{options.urls.length}):"
        options.urls.each { |url| puts " " + url }
      end

      if options.bail then
        puts "--bail invoked, terminating"
        exit
      end

      require "core/sqs-interface.rb"

      if options.size
        puts "url queue size: #{AWS::SQS::size}"
        exit
      end
      
      abort "no urls to inject" unless options.urls.length > 0

      options.urls.each do
        |url|
        options.repeat.times do 
          AWS::SQS::push_url url
          puts "injected " + url if options.verbose
        end
      end

      puts "done"
    end
  end
end
