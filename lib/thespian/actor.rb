require "thread"
require "monitor"
require "set"

require "thespian/errors"

module Thespian
  class Actor

    # If an actor died due to an exception, it is stored here.
    attr_reader :exception

    # Returns the actor's state.
    attr_reader :state

    attr_reader :strategy
    private :strategy

    # The state an actor is in after it has been created, but before it enters the message processing loop.
    STATE_INITIALIZED = :initialized

    # The state for when an actor is in the message processing loop.
    STATE_RUNNING = :running

    # The state for when an actor has exited the message processing loop (either by error or intentially).
    STATE_FINISHED = :finished

    DEFAULT_OPTIONS = {
      :mode      => :thread,
      :strict    => true,
      :trap_exit => false,
      :object    => nil
    } #:nodoc:

    # call-seq:
    #   new(options = {}){ |message| ... }
    #
    # Create a new actor using the given block to handles messages.  The actor will be in the +:initialized+
    # state, meaning the message processing loop hasn't started yet (see #start).
    #
    # +options+ are the same as specified by #options.
    def initialize(options = {}, &block)
      self.options(DEFAULT_OPTIONS.merge(options))

      @state         = :initialized
      @receive_block = block
      @linked_actors = Set.new

      @strategy = strategy_class.new{ run }
    end

    def strategy_class #:nodoc:
      class_name = options[:mode].to_s.capitalize
      Strategy.const_get(class_name)
    end

    # call-seq:
    #   options -> Hash
    #   options(hash) -> Hash
    #   options(symbol) -> value
    #
    # Get or set options.  Valid options are:
    # [:mode (default :thread)]
    #   What mode to create the actor in.  Choices are +:fiber+ or +:thread+.  When running in fibered mode,
    #   be sure that EventMachine's reactor is running and there is a root fiber.
    # [:strict (default true)]
    #   Require an actor to be running in order to put messages into its mailbox.
    # [:trap_exit (default false)]
    #   If true, the actor will get a DeadActorError message in its mailbox when a linked actor raises an unhandled exception.
    #
    # If given no arguments, returns a hash of options.
    #
    # If given a hash, sets the options specified in the hash.
    #
    # If given a symbol, returns that option's value.
    def options(arg = nil)
      @options ||= {}

      case arg
      when Hash
        @options.merge!(arg)
      when Symbol
        @options[arg]
      when nil
        @options
      end
    end

    # call-seq:
    #   link(actor)
    #
    # Exceptions in actors will be propogated to actors that are linked to them.  How they are propogated is
    # determined by the +:trap_exit+ option (see #options).
    #
    # +actor+ can either be an Actor instance or an instance of a class that included Thespian.
    def link(object)
      actor = object.kind_of?(Actor) ? object : object.actor
      actor.send(:_link, self)
      object
    end

    # Start the actor's message processing loop.
    # The thread that the loop is run on is guaranteed to have started by the time this method returns.
    def start

      # Don't let them start an already started actor.
      raise "already running" if running?

      # Can't raise an actor from the dead.
      raise @exception if @exception

      # IMPORTANT - Race condition!
      # This method and the thread both set @state. We don't want this method to
      # possibly overwrite how the thread sets @state, so we set the @state
      # before staring the thread.
      @state = :running

      @strategy.start
    end

    # Add a message to the actor's mailbox.
    # May raise an exception according to #check_alive!
    def <<(message)
      check_alive! if options(:strict)
      message = message.new if message == Stop
      @strategy << message
      self
    end

    # Stop the actor.
    # All pending messages will be processed before stopping the actor.
    # Raises an exception if the actor is not #running? and +:strict+ (see #options) is true.
    def stop
      check_alive! if options(:strict)
      self << Stop.new
      @strategy.stop
      raise @exception if @exception
    end

    # #state == :initialized
    def initialized?
      state == :initialized
    end

    # #state == :running
    def running?
      state == :running
    end

    # #state == :finished
    def finished?
      state == :finished
    end

    # Returns true if an error occurred that caused the actor to enter the :finished state.
    def error?
      !!@exception
    end

    # Returns how many messages are in the actor's mailbox.
    def mailbox_size
      @strategy.mailbox_size
    end

    # Salvage mailbox contents from a dead actor (including the message it died on).
    # Useful for restarting a dead actor while preserving its mailbox.
    def salvage_mailbox
      raise "cannot salvage mailbox from an actor that isn't finished" unless finished?
      @strategy.messages.tap do |messages|
        messages.unshift(@last_message) if @last_message
      end
    end

  private
    
    # This wraps the user's #act method.
    # It traps exceptions and notifies any linked actors.
    def run
      if options(:object)
        loop{ options(:object).instance_exec(receive, &@receive_block) }
      elsif @receive_block
        loop{ @receive_block.call(receive) }
      else
        loop{ receive }
      end
    rescue Stop
      nil
    rescue Exception => e
      @exception    = e
      @last_message = @message
    ensure
      @state = :finished
      notify_linked_of(@exception) if @exception
    end

    # Receive a message from the actor's mailbox.
    def receive

      # Communicate with #run by possibly raising exceptions here.
      case (message = @strategy.receive)
      when DeadActorError
        raise message unless options(:trap_exit)
      when Stop
        raise message
      end

      message # Return the message
    end

    # The other side of #link.
    def _link(actor)
      @linked_actors << actor
    end

    # Notifies all linked actors of the given exception, by adding it to their mailboxes.
    def notify_linked_of(exception)
      @linked_actors.each do |actor|
        actor << DeadActorError.new(options(:object) || self, exception)
      end
    end

    # An exception will be raised if the actor is not alive (is not running).
    # It will be a DeadActorError if died due to a linked actor, otherwise it will be a RuntimeError.
    def check_alive!
      return if running?
      if @exception
        raise @exception
      else
        raise RuntimeError, "actor is not running"
      end
    end

  end
end
