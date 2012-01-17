module Thespian
  class DeadActorError < RuntimeError

    # The actor or host object that died.
    attr_reader :actor

    # The exact exception that caused the actor to die.
    attr_reader :reason

    def initialize(actor, exception) #:nodoc:
      super(exception)
      @actor = actor
      @reason = exception
    end
  end

  # This is used as the stop message.
  class Stop < StandardError #:nodoc:
  end
end
