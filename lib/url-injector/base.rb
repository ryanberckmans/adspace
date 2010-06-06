require "core/util.rb"
require File.here "commandline-options.rb"
require File.here "load-data.rb"

module UrlInjector
  class << self
    def run
      options = UrlInjector::parse_options( ARGV )

      abort unless options

      urls = get_u_r_ls( options.url_file )

      if options.verbose then
        puts "urls to be injected into scanner (found #{urls.length}):"
        urls.each { |url| puts " " + url }
      end

      if options.bail then
        puts "--bail invoked, terminating"
        exit
      end

      require "core/sqs-interface.rb"

      urls.each do
        |url|
        AWS::SQS::push_url url
        puts "injected " + url if options.verbose
      end

      puts "done"
    end
  end
end
