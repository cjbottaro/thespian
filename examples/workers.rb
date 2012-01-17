require "thespian"

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
      @supervisor.actor << [:log, "#{id} worked for #{time.round(2)} seconds"]
      @supervisor.actor << [:ready, @id]
    end
  end

end

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
  rescue StandardError
    puts "!!!!!!!!!!!!!!!!!!!!!logger dead before message"
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
      puts "22222222222 #{old_mailbox.length}"
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
