require "thread"
require "monitor"

module Thespian
  module Strategy
    class Thread #:nodoc:

      include Interface

      attr_reader :thread

      def initialize(&block)
        @block        = block
        @mailbox      = []
        @mailbox_lock = Monitor.new
        @mailbox_cond = @mailbox_lock.new_cond
      end

      def start
        # Declare local synchronization vars.
        lock = Monitor.new
        cond = lock.new_cond
        wait = true

         # Start the thread and have it signal when it's running.
        @thread = ::Thread.new do
          lock.synchronize do
            wait = false
            cond.signal
          end
          @block.call
        end

        # Block until the thread has signaled that it's running.
        lock.synchronize do
          cond.wait_while{ wait }
        end
      end

      def receive
        @mailbox_lock.synchronize do
          @mailbox_cond.wait_while{ @mailbox.empty? }
          @mailbox.shift
        end
      end

      def <<(message)
        @mailbox_lock.synchronize do
          @mailbox << message
          @mailbox_cond.signal
        end
        self
      end

      def mailbox_size
        @mailbox_lock.synchronize do
          @mailbox.size
        end
      end

      def messages
        @mailbox_lock.synchronize do
          @mailbox.dup
        end
      end

      def stop
        self << Stop.new
        @thread.join
      end

    end
  end
end
