require "spec_helper"

require "eventmachine"
require "strand"

module Thespian
  module Strategy
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
  end
end
