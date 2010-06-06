require "core/util.rb"
require "rubygems"
require "right_aws"
require File.here "aws-interface.rb"

module AWS
  module SQS
    # SQS semantic notes:
    #  SQS is *not* FIFO, just I/O.
    #  in rare cases, a recieved message   i) may have already been deleted  ii) may be within its visibility timeout
    #   it is our responsibility to handle redundant/duplicate messages

    URL_QUEUE = "url-queue"
    PROCESS_MATCHES_QUEUE = "process-matches"
    URL_QUEUE_VISIBILITY = 120 # seconds
    PROCESS_MATCHES = "process-matches"
    
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

      # process_matches_queue should be a publish/subscribe slots/signals implementation using AWS::SimpleNotificationService, but no ruby SNS client atm
      begin
        @@process_matches_queue = @@sqs.queue(PROCESS_MATCHES_QUEUE)
      rescue Exception => e
        puts e.message
        puts "error creating/retrieving process-matches queue"
        raise
      end

      def clear
        @@url_queue.delete
        @@process_matches_queue.delete
        # helper method for testing, does not recreate the queues, so the module cannot be used after calling this method
      end

      def process_matches
        begin
          @@process_matches_queue.push PROCESS_MATCHES
        rescue Exception =>e 
          puts e.message
          raise
        end
      end

      def process_matches?
        begin
          @@process_matches_queue.pop
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





