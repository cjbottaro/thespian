require "spec_helper"

module Thespian
  describe Actor do

    context "#new" do
      let(:actor){ Actor.new }

      it "returns a new Actor" do
        actor.should be_a(Actor)
      end

      it "that is initialized" do
        actor.should be_initialized
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
      let(:actor){ Actor.new.extend(ActorHelper) }

      before(:all) do
        actor.start
      end

      it "marks the actor as alive" do
        actor.should be_running
      end

      it "starts a thread" do
        actor.thread.should be_alive
      end
    end

    context "#receive" do
      let(:actor){ Actor.new.extend(ActorHelper) }

      it "returns the next message from the actor's mailbox" do
        actor.mailbox << "hello"
        actor.receive.should == "hello"
      end

      it "raises a DeadActorError if that's what's in the mailbox" do
        actor.mailbox << DeadActorError.new(actor, "blah")
        expect{ actor.receive }.to raise_error(DeadActorError)
      end

      it "raises a Stop exception if that's what's in the mailbox" do
        actor.mailbox << Stop.new
        expect{ actor.receive }.to raise_error(Stop)
      end

      it "returns DeadActorError if trap_exit is true and that's what's in the mailbox" do
        actor.mailbox << DeadActorError.new(actor, "blah")
        actor.options(:trap_exit => true)
        actor.receive.should be_a(DeadActorError)
      end
    end

    context "#<<" do
      let(:actor){ Actor.new.extend(ActorHelper) }

      it "puts an item into the mailbox" do
        stub(actor).running?{ true }
        actor << "hello"
        actor.mailbox.should include("hello")
      end

      it "raises a RuntimeError if the actor isn't alive" do
        actor.should_not be_running
        expect{ actor << "hello" }.to raise_error(RuntimeError, /not running/i)
      end

      it "works on a dead actor if strict is false" do
        actor.should_not be_running
        actor.options :strict => false
        actor << "blah"
        actor.mailbox.should include("blah")
      end
    end

    context "#stop" do
      let(:actor){ Actor.new.extend(ActorHelper) }

      it "raises an exception if the actor isn't alive" do
        expect{ actor.stop }.to raise_error(RuntimeError, /not running/i)
      end

      it "puts a Stop message in the actor's mailbox" do
        mock(actor).running?{ true }.times(2)
        mock(actor.thread).join
        actor.stop
        actor.mailbox[0].should be_a(Stop)
      end
    end

    context "#salvage_mailbox" do

      it "raises an error if the actor isn't done" do
        actor = Actor.new
        expect{ actor.salvage_mailbox }.to raise_error(/isn't finished/i)
      end

      it "doesn't include the last message if the actor stopped properly" do
        actor = Actor.new.extend(ActorHelper)
        actor.mailbox.replace([1, 2, 3, Stop.new, 4, 5])
        actor.start
        Thread.pass while actor.running?
        actor.salvage_mailbox.should == [4, 5]
      end

      it "includes the last message if the actor error'ed" do
        actor = Actor.new do |message|
          raise "oops" if message == 3
        end.extend(ActorHelper)
        actor.mailbox.replace([1, 2, 3, 4, 5])
        actor.start
        Thread.pass while actor.running?
        actor.salvage_mailbox.should == [3, 4, 5]
      end

    end

  end
end
