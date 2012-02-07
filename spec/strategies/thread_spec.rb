require "spec_helper"

module Thespian
  module Strategy
    describe Thread do

      let(:strategy){ Thread.new{ nil } }

      it_should_behave_like Interface do
        def sleep(n = nil)
          Kernel.sleep(n)
        end
      end

    end
  end
end
