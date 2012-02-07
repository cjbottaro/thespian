require "thread"
require "monitor"
require "json"

module Thespian
  module Strategy
    class Process #:nodoc:

      include Interface

      def initialize(&block)
        @block        = block
        @mailbox      = []
        @mailbox_lock = Monitor.new
        @mailbox_cond = @mailbox_lock.new_cond
        @p_read, @p_write = IO.pipe
        @c_read, @c_write = IO.pipe
      end

      def start
        if fork
          self
        else
          ::Thread.new{ puts "in thread"; command_loop }
          puts "calling block"
          @block.call
        end
      end

      def receive
        @mailbox_lock.synchronize do
          @mailbox_cond.wait_while{ @mailbox.empty? }
          @mailbox.shift
        end
      end

      def <<(message)
        @c_write.puts(JSON.dump({ "cmd" => "message", "payload" => Marshal.dump(message) }))
        @c_write.flush
        puts "written"
      end

      def mailbox_size
        @c_write.puts(JSON.dump({ "cmd" => "mailbox_size" }))
        @c_write.flush
        @p_read.readline.chomp.to_i
      end

      def command_loop
        puts "in command loop"
        while line = @c_read.readline
          puts "!!! #{line}"
          hash = JSON.parse(line)
          send("cmd_%s" % hash["cmd"], hash)
        end
      end

      def cmd_message(hash)
        message = Marshal.load(hash["payload"])
        @mailbox_lock.synchronize do
          @mailbox << message
          @mailbox_cond.signal
        end
      end

      def cmd_mailbox_size(hash)
        @p_write.puts(@mailbox.size)
        @p_write.flush
      end

    end
  end
end
