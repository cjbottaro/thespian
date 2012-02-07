require "spec_helper"

module Thespian
  describe Actor do

    let(:actor){ Actor.new.extend(ActorHelper) }

    context "#new" do

      it "returns a new Actor" do
        actor.should be_a(Actor)
      end

      it "that is initialized" do
        actor.should be_initialized
      end

      it "using the Thread strategy" do
        actor.strategy.should be_a(Strategy::Thread)
      end

      it "using the Fiber strategy" do
        actor = Actor.new(:mode => :fiber).extend(ActorHelper)
        actor.strategy.should be_a(Strategy::Fiber)
      end

    end

    context "#link" do
      let(:actor1){ Actor.new.extend(ActorHelper) }
      let(:actor2){ Actor.new.extend(ActorHelper) }

      it "adds self to the other actor's linked list" do
        actor1.link(actor2)
        actor2.linked_actors.should include(actor1)
        actor1.linked_actors.should_not include(actor2)
      end

      it "can take host objects as argument" do
        host = Class.new{ include Thespian }.new
        host.actor.extend(ActorHelper)

        actor1.link(host)
        host.actor.linked_actors.should include(actor1)
        actor1.linked_actors.should_not include(host.actor)
      end
    end

    context "#start" do

      before(:each) do
        stub(actor.strategy).start
        actor.start
      end

      it "marks the actor as alive" do
        actor.should be_running
      end

      it "calls Strategy#start" do
        actor.strategy.should have_received.start
      end
    end

    context "#receive" do

      it "returns the next message from the actor's mailbox" do
        mock(actor.strategy).receive{ "hello" }
        actor.receive.should == "hello"
      end

      it "raises a DeadActorError if that's what's in the mailbox" do
        mock(actor.strategy).receive{ DeadActorError.new(actor, "blah") }
        expect{ actor.receive }.to raise_error(DeadActorError)
      end

      it "raises a Stop exception if that's what's in the mailbox" do
        mock(actor.strategy).receive{ Stop.new }
        expect{ actor.receive }.to raise_error(Stop)
      end

      it "returns DeadActorError if trap_exit is true and that's what's in the mailbox" do
        mock(actor.strategy).receive{ DeadActorError.new(actor, "blah") }
        actor.options(:trap_exit => true)
        actor.receive.should be_a(DeadActorError)
      end
    end

    context "#<<" do

      it "puts an item into the mailbox" do
        stub(actor).running?{ true }
        mock(actor.strategy).<<("hello")
        actor << "hello"
      end

      it "raises a RuntimeError if the actor isn't alive" do
        actor.should_not be_running
        expect{ actor << "hello" }.to raise_error(RuntimeError, /not running/i)
      end

      it "works on a dead actor if strict is false" do
        actor.should_not be_running
        actor.options :strict => false
        mock(actor.strategy).<<("blah")
        actor << "blah"
      end
    end

    context "#stop" do

      it "raises an exception if the actor isn't alive" do
        expect{ actor.stop }.to raise_error(RuntimeError, /not running/i)
      end

      it "puts a Stop message in the actor's mailbox" do
        stub(actor).check_alive!{ true }
        mock(actor.strategy).<<(is_a(Stop))
        mock(actor.strategy).stop
        actor.stop
      end
    end

    context "#salvage_mailbox" do

      it "raises an error if the actor isn't done" do
        actor = Actor.new
        expect{ actor.salvage_mailbox }.to raise_error(/isn't finished/i)
      end

      it "doesn't include the last message if the actor stopped properly" do
        mock(actor.strategy).messages{ [2, 3] }
        mock(actor).finished?{ true }
        actor.salvage_mailbox.should == [2, 3]
      end

      it "includes the last message if the actor error'ed" do
        actor.instance_eval{ @last_message = 1 }
        mock(actor.strategy).messages{ [2, 3] }
        mock(actor).finished?{ true }
        actor.salvage_mailbox.should == [1, 2, 3]
      end

    end

    context "#mailbox_size" do

      it "returns how many messages are in the mailbox" do
        mock(actor.strategy).mailbox_size{ 3 }
        actor.mailbox_size.should == 3
      end

    end

  end
end
