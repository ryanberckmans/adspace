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

      $SQS_QUEUE = options.sqs_queue if options.sqs_queue
      puts "using sqs queue #{$SQS_QUEUE}" if $SQS_QUEUE
      require "core/sqs-interface.rb"

      if options.size
        puts "url queue size: #{AWS::SQS::size}"
        exit
      end

      if options.clear
        AWS::SQS::clear rescue nil
        msg = "cleared the queue"
        msg += " #{$SQS_QUEUE}" if $SQS_QUEUE
        puts msg
        exit
      end
      
      abort "no urls to inject" unless options.urls.length > 0

      options.urls.each do
        |url|
        options.repeat.times do 
          AWS::SQS::push_url url
          puts "injected " + url if options.verbose
          sleep 0.15 # don't hit sqs so hard. they can handle it but we crash sometimes
        end
      end

      puts "done"
    end
  end
end
