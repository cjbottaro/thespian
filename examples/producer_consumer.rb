require "thespian"

producer = nil
consumer = nil

producer = Thespian::Actor.new do |message|
  case message
  when :need_item
    consumer << rand
  else
    raise "unexpected message: #{message}"
  end
end

consumer = Thespian::Actor.new do |message|
  sleep(message)
  puts "consumer got #{message}"
  producer << :need_item
end

producer.start
consumer.start
producer << :need_item
sleep
