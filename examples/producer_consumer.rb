require "thespian"
require "thespian/example"

Thespian::Example.run do

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
  while true
    sleep(1)
    puts "Total threads: #{Thread.list.length}"
  end

end
