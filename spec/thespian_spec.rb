module Thespian

  describe Thespian do
    context "when included in a class" do

      let(:klass){ Class.new{ include Thespian } }

      it "defines #actor on the class" do
        klass.should respond_to(:actor)
      end

      it "defines #actor on instances of the class" do
        klass.new.should respond_to(:actor)
      end

      context "#actor on the class" do

        before(:each) do
          klass.actor.instance_variable_set(:@receive_block, nil)
        end

        it "defines how messages should be processed" do
          klass.actor.receive_block.should be_nil
          klass.actor{ |message| nil }
          klass.actor.receive_block.should be_a(Proc)
        end

        it "has method #receive which also defines how messages should be processed" do
          klass.actor.receive_block.should be_nil
          klass.actor.receive{ |message| nil }
          klass.actor.receive_block.should be_a(Proc)
        end

        if supports_fibers?
          it "allows you to set mode when defining the message handling block" do
            klass.new.actor.options[:mode].should == :thread
            klass.actor(:mode => :fiber){ |message| nil }
            klass.new.actor.options[:mode].should == :fiber
            klass.actor(:mode => :thread){ |message| nil }
            klass.new.actor.options[:mode].should == :thread
          end

          it "allows you to set mode" do
            klass.new.actor.options[:mode].should == :thread
            klass.actor.options[:mode] = :fiber
            klass.actor{ |message| nil }
            klass.new.actor.options[:mode].should == :fiber
          end
        end

      end

      context "#actor on instances of the class" do

        it "returns an instance of Actor" do
          object = klass.new
          object.actor.should be_an(Actor)
        end

      end

    end
  end

end
