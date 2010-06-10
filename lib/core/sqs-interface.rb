require "core/util.rb"
require "rubygems"
require "right_aws"
require Util.here "aws-interface.rb"

Rightscale::HttpConnection::params = { :http_connection_retry_delay=>5, :http_connection_retry_count=>3, :http_connection_open_timeout=>5, :http_connection_read_timeout=>1200}

module AWS
  module SQS
    # SQS semantic notes:
    #  SQS is *not* FIFO, just I/O.
    #  in rare cases, a recieved message   i) may have already been deleted  ii) may be within its visibility timeout
    #   it is our responsibility to handle redundant/duplicate messages

    URL_QUEUE = "url-queue"
    COMMAND_QUEUE = "command-queue"
    URL_QUEUE_VISIBILITY = 180 # seconds

    PROCESS_MATCHES = "process-matches"
    SHUTDOWN = "shutdown"
    
    class << self

      begin
        @@sqs = RightAws::SqsGen2.new( AWS::access_key, AWS::secret_access_key )
      rescue Exception => e
        puts e.message
        puts "error creating sqs connection"
        raise
      end

      begin
        @@url_queue = @@sqs.queue(URL_QUEUE, true, URL_QUEUE_VISIBILITY)
      rescue Exception => e
        puts e.message
        puts "error creating/retrieving url queue"
        raise
      end

      # command_queue should be a publish/subscribe slots/signals implementation using AWS::SimpleNotificationService, but no ruby SNS client atm
      begin
        @@command_queue = @@sqs.queue(COMMAND_QUEUE)
      rescue Exception => e
        puts e.message
        puts "error creating/retrieving #{COMMAND_QUEUE} queue"
        raise
      end

      def clear
        @@url_queue.delete
        @@command_queue.delete
        # helper method for testing, does not recreate the queues, so the module cannot be used after calling this method
      end

      def process_matches
        begin
          @@command_queue.push PROCESS_MATCHES
        rescue Exception =>e
          puts e.backtrace
          puts e.message
          raise
        end
      end

      def shutdown
        begin
          @@command_queue.push SHUTDOWN
        rescue Exception =>e
          puts e.backtrace
          puts e.message
          raise
        end
      end

      def command?
        begin
          m = @@command_queue.pop
          m = m.to_s if m
          m
        rescue Exception =>e 
          puts e.message
          nil
        end
      end        
      
      def push_url( url )
        begin
          @@url_queue.push url
        rescue Exception =>e 
          puts e.message
          raise
        end
      end
      
      def next_url
        begin
          @@url_queue.receive
        rescue Exception => e
          puts e.message
          raise
        end
      end
      
      def done_with_next_url( url_message )
        begin
          url_message.delete
        rescue Exception => e
          puts e.message
        end
      end
      
    end # class << self
  end # module SQS
end # module AWS





