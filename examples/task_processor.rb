require "thespian"

# The actors are Supervisor, Logger, Poller, Worker(s).  There is one of each except for multiple
# workers.  The basic idea is that the supervisor can send messages to any other actor, but all
# other actors can only send messages to the supervisor.  In other words the non-supervisor actors
# cannot directly communicate with each other; they have to go through the supervisor.

# This actor just sits and waits for log messages to print out.  It has a 10% chance of erroring
# on each message it processes.
class Logger
  include Thespian

  def initialize
    actor.options(:strict => false)
  end

  actor.receive do |message|
    if rand > 0.90
      raise "logger oops"
    else
      puts message
    end
  end

end

# This actor is sent "work" messages.  When it's done with the work, it will send a message
# with its id back to the supervisor saying that it's ready for more work.
# It has a 10% chance of dying while processing a message.
class Worker
  include Thespian
  attr_reader :id

  def initialize(id, supervisor)
    @id = id
    @supervisor = supervisor
    actor.start
  end
  
  actor.receive do |message|
    raise "oops worker" if rand > 0.90

    cmd, *args = message

    case cmd
    when :work
      time, = *args
      sleep(time)
      @supervisor.actor << [:log, "worker ##{id} worked for #{time.round(2)} seconds"]
      @supervisor.actor << [:ready, @id]
    end
  end

end

# This actor is responsible for getting "work" for a worker to do.  The supervisor will
# send it a "get work" message, once it's retreived the work (maybe from a queue if this
# was in the real world), it will send it back to the supervisor as "task ready" message.
class Poller
  include Thespian

  def initialize(supervisor)
    actor.options :strict => false
    @supervisor = supervisor
  end

  actor.receive do |cmd, *args|
    raise "oops poller" if rand > 0.90
    sleep(0.2)
    case cmd
    when :get
      @supervisor.actor << [:task, rand]
    end
  end

end

# The supervisor is responsible for coordinating all the actors.  It's also responsible for
# restarting any other actors that die (hence it needs to link to all of them).
#
# The basic idea is that the supervisor starts up each actor, then keeps a list of idle workers.
# For each idle worker, it asks the poller for a task.  When the poller responds with a task,
# it sends the task to the worker and removes the worker from the idle list.  When the worker
# reports that it is finished, the worker is placed back in the idle list and the supervisor
# asks the poller for another task.
class Supervisor
  include Thespian

  def initialize(count)
    @ready = []
    actor.options(:trap_exit => true)
    actor.start
    initialize_logger
    initialize_poller
    count.times{ |id| initialize_worker(id) }
  end

  actor.receive do |message|
    case message
    when Thespian::DeadActorError
      handle_dead_actor(message.actor)
    when Array
      cmd, *args = message
      send("do_#{cmd}", *args)
    end
  end

  def handle_dead_actor(actor)
    case actor
    when Logger
      do_log("logger died, restarting")
      initialize_logger
    when Worker
      do_log("worker(#{actor.id}) died, restarting")
      initialize_worker(actor.id)
    when Poller
      do_log("poller died (#{@ready.length}, #{@poller.actor.instance_eval{ @mailbox }.length}), restarting")
      initialize_poller
    end
  end

  def do_log(message)
    @logger.actor << message
  end

  def do_ready(id)
    @ready << id
    @poller.actor << [:get]
  end

  def do_task(arg)
    id = @ready.shift
    @workers[id].actor << [:work, arg]
  end

  def initialize_logger
    if @logger
      old_mailbox = @logger.actor.salvage_mailbox
    end
    @logger = Logger.new
    actor.link(@logger)
    if old_mailbox
      old_mailbox.each{ |message| @logger.actor << message }
    end
    @logger.actor.start
  end

  def initialize_poller
    @poller = Poller.new(self)
    @ready.each{ @poller.actor << [:get] }
    actor.link(@poller)
    @poller.actor.start
  end

  def initialize_worker(id)
    @workers ||= []
    @workers[id] = Worker.new(id, self).tap do |worker|
      @ready << id
      actor.link(worker)
      @poller.actor << [:get]
    end
  end

end

s = Supervisor.new(5)
while true
  raise s.actor.exception unless s.actor.running?
  sleep(1)
end
