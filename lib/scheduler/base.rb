require "core/util.rb"
require Util.here "commandline-options.rb"
require "core/coroutine.rb"

module Scheduler
  INTERVAL = 60 * 1
  DESIRED_INTERVALS = 4
  NEW_RATE_RATIO = 0.5
  MINIMUM_QUEUE_SIZE = 20

  def self.consumption_tracker( coroutine )
    previous_size = 0
    consumption_rate = 0.0
    while true
      previous_size = AWS::SQS::size rescue previous_size
      coroutine.yield
      size = AWS::SQS::size rescue previous_size
      puts previous_size
      puts size
      consumption_rate = consumption_rate * NEW_RATE_RATIO + (previous_size - size) * (1 - NEW_RATE_RATIO)
      puts "consumption_rate: #{consumption_rate}"
      increase_queue_by = DESIRED_INTERVALS * [consumption_rate,0.0].max - size
      coroutine.yield [increase_queue_by.to_i,0,MINIMUM_QUEUE_SIZE - size].max
    end
  end
  
  def self.run
    options = Scheduler::parse_options ARGV

    $SQS_QUEUE = options.sqs_queue
    puts "using sqs queue #{$SQS_QUEUE}"
    require "core/sqs-interface.rb"

    consumption = Coroutine.new { |cr| consumption_tracker cr }
    
    while true
      consumption.resume
      sleep INTERVAL
      increase_queue_by = consumption.resume
      puts "final increase queue by #{increase_queue_by}"
    end
  end
end
