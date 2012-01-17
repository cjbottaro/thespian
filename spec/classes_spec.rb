module Thespian
  describe "Thespian when used with classes" do

    it "processes messages with the block defined by the actor method in the class" do
      klass = Class.new do
        attr_reader :messages
        include Thespian
        actor do |message|
          @messages ||= []
          @messages << message
        end
      end

      object = klass.new
      object.actor.start
      object.actor << 1 << 2 << 3
      object.actor.stop
      object.messages.should == [1, 2, 3]
    end

  end
end
