begin
  require "fiber"
rescue LoadError
  raise "Thespian requires Ruby >= 1.9 to run in fibered mode"
end

require "strand"

module Thespian
  module Strategy
    class Fiber #:nodoc:

      include Interface

      def initialize(&block)
        @block        = block
        @mailbox      = []
        @mailbox_cond = Strand::ConditionVariable.new
      end

      def start
        @strand = Strand.new{ @block.call }
        self
      end

      def receive
        @mailbox_cond.wait while @mailbox.empty?
        @mailbox.shift
      end

      def <<(message)
        @mailbox << message
        @mailbox_cond.signal
        self
      end

      def mailbox_size
        @mailbox.size
      end

      def messages
        @mailbox.dup
      end

      def stop
        self << Stop.new
        @strand.join
      end

    end
  end
end
