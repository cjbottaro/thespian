module Thespian
  module Strategy #:nodoc:

    autoload :Thread, "thespian/strategies/thread"
    autoload :Fiber,  "thespian/strategies/fiber"

    module Interface #:nodoc:

      def start
        raise "not implemented"
      end

      def receive
        raise "not implemented"
      end

      def <<(message)
        raise "not implemented"
      end

      def mailbox_size
        raise "not implemented"
      end

      def stop
        raise "not implemented"
      end

      def salvage_mailbox
        raise "not implemented"
      end

    end
  end
end
