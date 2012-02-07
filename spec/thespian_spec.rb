module Thespian

  describe Thespian do
    context "when included in a class" do

      before(:all) do
        @class = Class.new do
          include Thespian
        end
      end

      it "defines #actor on the class" do
        @class.should respond_to(:actor)
      end

      it "defines #actor on instances of the class" do
        @class.new.should respond_to(:actor)
      end

      context "#actor on the class" do

        before(:each) do
          @class.actor.instance_variable_set(:@receive_block, nil)
        end

        it "defines how messages should be processed" do
          @class.actor.receive_block.should be_nil
          @class.actor{ |message| nil }
          @class.actor.receive_block.should be_a(Proc)
        end

        it "has method #receive which also defines how messages should be processed" do
          @class.actor.receive_block.should be_nil
          @class.actor.receive{ |message| nil }
          @class.actor.receive_block.should be_a(Proc)
        end

        it "allows you to set options when defining the message handling block" do
          @class.new.actor.options[:mode].should == :thread
          @class.actor(:mode => :fiber){ |message| nil }
          @class.new.actor.options[:mode].should == :fiber
          @class.actor(:mode => :thread){ |message| nil }
          @class.new.actor.options[:mode].should == :thread
        end

        it "allows you to set options" do
          @class.new.actor.options[:mode].should == :thread
          @class.actor.options[:mode] = :fiber
          @class.actor{ |message| nil }
          @class.new.actor.options[:mode].should == :fiber
        end

      end

      context "#actor on instances of the class" do

        it "returns an instance of Actor" do
          object = @class.new
          object.actor.should be_an(Actor)
        end

      end

    end
  end

end
