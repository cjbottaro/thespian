require "thespian"

class Worker
  include Thespian

  actor.receive do |message|
    case message
    when Fixnum
      puts "received #{message}"
    when String
      raise "I can only work with Fixnums!"
    end
  end
end

class Supervisor
  include Thespian

  def initialize
    @worker = actor.link(Worker.new)
    @worker.actor.start
    @worker.actor << 1
    @worker.actor << 2
    @worker.actor << "3"
  end

  actor.receive do |message|
    puts message
  end
end


s = Supervisor.new
s.actor.start
sleep(1)
puts s.actor.running?
s.actor.stop
