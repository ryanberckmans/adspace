require "optparse"
require "ostruct"

module Scheduler
  def self.parse_options( argv )
    collected_options = OpenStruct.new

    collected_options.sqs_queue = nil

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: scheduler [options]"
      opts.separator ""
      opts.separator "Specific options:"
      
      opts.on("--sqs QUEUE", String, "required. use QUEUE instead of the default sqs queue") do |queue|
        collected_options.sqs_queue = queue
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
