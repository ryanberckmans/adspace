require "core/util.rb"
require Util.here "commandline-options.rb"

module Scheduler
  INTERVAL = 60 * 2
  DESIRED_INTERVALS = 4
  NEW_RATE_RATIO = 0.5

  def self.run
    options = Scheduler::parse_options ARGV

    $SQS_QUEUE = options.sqs_queue
    puts "using sqs queue #{$SQS_QUEUE}"
    require "core/sqs-interface.rb"

    consumption_rate = 0.0
    previous_size = 0
    
    while true
      previous_size = AWS::SQS::size rescue previous_size
      sleep INTERVAL
      size = AWS::SQS::size rescue previous_size
      puts previous_size
      puts size
      consumption_rate = consumption_rate * NEW_RATE_RATIO + (previous_size - size) * (1 - NEW_RATE_RATIO)
      puts "consumption_rate: #{consumption_rate}"
      intervals_remaining = size / [consumption_rate,0.0].max
      puts "intervals' worth of work remaining: #{intervals_remaining}"
      puts "top-up required" if intervals_remaining < DESIRED_INTERVALS
      # TOP UP
    end
  end
end
