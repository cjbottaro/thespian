require "thespian"

producer = nil
consumer = nil
n = 0

producer = Thespian::Actor.new do |message|
  case message
  when :need_item
    if (n += 1) < 10
      consumer << rand
    else
      consumer << "bad message"
    end
  else
    raise "unexpected message: #{message}"
  end
end

consumer = Thespian::Actor.new do |message|
  case message
  when Float
    puts "consumer got #{message}"
    producer << :need_item
  else
    raise "I can only work with numbers!"
  end
end

producer.link(consumer)
producer.start
consumer.start
producer << :need_item
Thread.pass while consumer.running?
puts consumer.finished?  # True
puts consumer.error?     # True
puts producer.finished?  # True because it's linked to the consumer
puts producer.error?     # True because it's linked to the consumer
puts producer.exception
