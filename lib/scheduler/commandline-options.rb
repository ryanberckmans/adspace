require "optparse"
require "ostruct"

module Scheduler
  def self.parse_options( argv )
    collected_options = OpenStruct.new

    collected_options.urls = []
    collected_options.sqs_queue = nil
    collected_options.size = false
    collected_options.clear = false
    collected_options.bail = false

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: scheduler [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on("--sqs QUEUE", String, "required. use QUEUE instead of the default sqs queue") do |queue|
        collected_options.sqs_queue = queue
      end

      opts.on("--url URL", String, "optional. inject URL. use --url any number of times. each URL must be prefixed with transport protocol (i.e. http://)") do |url|
        collected_options.urls.push url
      end

      opts.on("-s", "--size", "optional. return the current size of the queue and then exit") do
        collected_options.size = true
        collected_options.bail = true
      end

      opts.on("-c", "--clear-queue", "optional. clear the queue and then exit") do
        collected_options.clear = true
        collected_options.bail = true
      end

      opts.on("-b", "--bail", "optional. perform initial tasks but do not execute scheduler main loop") do
        collected_options.bail = true
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opts.parse!(argv)
    
    collected_options
  end
end
