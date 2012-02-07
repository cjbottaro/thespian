module Thespian
  # This class aids in running the examples in the different modes.
  #
  # To run in threaded mode, just run without arguments:
  #   bundle exec ruby examples/task_processor.rb
  # To run in fibered mode:
  #   bundle exec ruby examples/task_processor.rb --fiber
  # This class does all the necessary incantations necessary to run
  # in fibered mode (starts/stops EventMachine, wraps in root fiber, etc).
  class Example

    # Determine what mode to run in by looking at ARGV then invoke the block given.
    # If running in fibered mode, the block will be wrapped with necessary calls
    # to EventMachine and Fiber.  It will also make sure to define fiber
    # safe versions of #sleep and #pass that the example can use.
    def self.run(&example)
      if ARGV.include?("--fiber") || ARGV.include?("--fibers")
        require "eventmachine"
        require "strand"
        EM.run do
          Strand.new do
            puts "Running example with fibers..."
            Thespian::Actor::DEFAULT_OPTIONS[:mode] = :fiber
            example.binding.eval <<-CODE
              def sleep(n); Strand.sleep(n); end
              def pass; Strand.pass; end
            CODE
            example.call
            EM.stop
          end
        end
      else
        puts "Running example with threads..."
        example.binding.eval <<-CODE
          def pass; Thread.pass; end
        CODE
        example.call
      end
    end
  end
end
