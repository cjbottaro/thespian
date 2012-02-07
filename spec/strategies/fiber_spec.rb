require "spec_helper"

module Thespian
  module Strategy

    if supports_fibers?

      require "eventmachine"
      require "strand"

      describe Fiber do

        let(:strategy){ Fiber.new{ nil } }

        around(:each) do |example|
          EM.run do
            Strand.new do
              example.run
              EM.stop
            end
          end
        end

        it_should_behave_like Interface do
          def sleep(n)
            Strand.sleep(n)
          end
        end

      end

    else

      describe "Fiber" do
        it "requires ruby 1.9 or higher" do
        end
      end

    end

  end
end
