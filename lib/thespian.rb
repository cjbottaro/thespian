require "thespian/actor"
require "thespian/dsl"
require "thespian/version"

require "thespian/strategies/interface"

# Include this module into classes to give them acting abilities.
#   class ArnoldSchwarzenegger
#     include Thespian
# 
#     actor.receive do |message|
#       handle_message(message)
#     end
#
#     def handle_message(message)
#       puts message
#     end
#   end
#
#   arnold = ArnoldSchwarzenegger.new
#   arnold.actor.start
#   arnold.actor << "I'm a cop, you idiot!"
#   arnold.actor.stop
#
# For a general overview of this gem, see the README.rdoc.
module Thespian

  def self.included(mod) #:nodoc:
    mod.send(:extend,  ClassMethods)
    mod.send(:include, InstanceMethods)
  end

  module ClassMethods #:nodoc:
    
    def actor(options = nil, &block)
      @actor ||= Dsl.new
      @actor.options = options if options
      if block_given?
        @actor.receive(&block)
      else
        @actor
      end
    end

  end

  module InstanceMethods #:nodoc:

    def actor
      @actor ||= Actor.new(self.class.actor.options.merge(:object => self), &self.class.actor.receive_block)
    end

  end
end
