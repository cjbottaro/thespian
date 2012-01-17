require "thespian"
class Consumer
  include Thespian

  actor.receive do |message|
    handle_message(message)
  end

  def handle_message(message)
    sleep(message)
    puts "I slept for #{message} seconds"
  end
end

consumer = Consumer.new
consumer.actor.start
consumer.actor << rand
consumer.actor << rand
consumer.actor << rand
consumer.actor.stop
