require "core/log.rb"
require "core/util.rb"
require "rubygems"
require "right_aws"
require Util.here "aws-interface.rb"

Rightscale::HttpConnection::params = { :http_connection_retry_delay=>5, :http_connection_retry_count=>3, :http_connection_open_timeout=>5, :http_connection_read_timeout=>1200, :logger => Log::get }

module AWS
  module SQS
    # SQS semantic notes:
    #  SQS is *not* FIFO, just I/O.
    #  in rare cases, a recieved message   i) may have already been deleted  ii) may be within its visibility timeout
    #   it is our responsibility to handle redundant/duplicate messages

    QUEUE_NAME = $SQS_QUEUE || "scan-queue"
    QUEUE_VISIBILITY = 180 # seconds

    class << self

      begin
        @@sqs = RightAws::SqsGen2.new( AWS::access_key, AWS::secret_access_key, { :logger => Log::get } )
      rescue Exception => e
        Log::error e.backtrace.join "\t"
        Log::error "#{e.class} #{Util::strip_newlines e.message}"
        Log::error "error creating sqs connection"
        raise
      end

      begin
        @@queue = @@sqs.queue(QUEUE_NAME, true, QUEUE_VISIBILITY)
      rescue Exception => e
        Log::error e.backtrace.join "\t"
        Log::error "#{e.class} #{Util::strip_newlines e.message}"
        Log::error "error creating/retrieving queue"
        raise
      end

      def clear
        @@queue.delete
      end

      def push( message )
        begin
          @@queue.push message
        rescue Exception =>e
          Log::error e.backtrace.join "\t"
          Log::error "#{e.class} #{Util::strip_newlines e.message}"
          raise
        end
      end

      def next
        begin
          @@queue.receive
        rescue Exception => e
          Log::error e.backtrace.join "\t"
          Log::error "#{e.class} #{Util::strip_newlines e.message}"
          nil
        end
      end
      
      def done_with_next( message )
        begin
          message.delete
        rescue Exception => e
          Log::error e.backtrace.join "\t"
          Log::error "#{e.class} #{Util::strip_newlines e.message}"
        end
      end

      def size
        @@queue.size
      end
      
    end # class << self
  end # module SQS
end # module AWS





