require "spec_helper"

module Thespian
  module Strategy

    shared_examples_for Interface do

      context "#start" do

        before(:all){ File.unlink("test.txt") rescue nil }
        after(:all){ File.unlink("test.txt") rescue nil }

        it "eventually calls the block" do
          described_class.new{ File.open("test.txt", "w") }.start
          count = 0
          while not File.exists?("test.txt") and count < 5
            sleep(0.01)
            count += 1
          end
          File.should exist("test.txt")
        end

      end

      context "#<<" do

        it "should put a message in the mailbox" do
          strategy << :message
          strategy.mailbox_size.should == 1
          strategy.receive.should == :message
        end

      end

      context "#receive" do

        it "should return a message from the mailbox" do
          strategy << 1 << 2 << 3
          strategy.mailbox_size.should == 3
          strategy.receive.should == 1
          strategy.receive.should == 2
          strategy.receive.should == 3
        end

      end

      context "#mailbox_size" do

        it "returns how many messages are in the mailbox" do
          strategy << 1
          strategy.mailbox_size.should == 1
          strategy << 1
          strategy.mailbox_size.should == 2
          strategy.receive
          strategy.mailbox_size.should == 1
          strategy.receive
          strategy.mailbox_size.should == 0
        end

      end

      context "#messages" do

        it "returns an array of messages" do
          strategy << 1
          strategy.messages.should == [1]
          strategy << 2
          strategy.messages.should == [1, 2]
        end

      end

      context "#stop" do

        before(:each){ strategy.start }

        it "puts a stop message in the mailbox" do
          strategy.stop
          strategy.messages.should include(Stop.new)
        end

        it "blocks until the async primitive is done" do
          strategy.stop
        end

      end

    end

  end
end
