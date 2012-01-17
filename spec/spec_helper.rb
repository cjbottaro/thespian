require "thespian"

module ActorHelper

  def linked_actors
    @linked_actors
  end

  def thread
    @thread
  end

  def mailbox
    @mailbox
  end

  def mailbox_cond
    @mailbox_cond
  end

  # To get around receive being private
  def receive
    super
  end

end

require 'rr'

module RR
  module Adapters
    module RSpec2

      include RRMethods

      def setup_mocks_for_rspec
        RR.reset
      end
      def verify_mocks_for_rspec
        RR.verify
      end
      def teardown_mocks_for_rspec
        RR.reset
      end

      def have_received(method = nil)
        RR::Adapters::Rspec::InvocationMatcher.new(method)
      end
    end
  end
end

RSpec.configuration.backtrace_clean_patterns.push(RR::Errors::BACKTRACE_IDENTIFIER)

module RSpec
  module Core
    module MockFrameworkAdapter
      include RR::Adapters::RSpec2
    end
  end
end

RSpec.configure do |config|
  config.mock_with :rr
end

