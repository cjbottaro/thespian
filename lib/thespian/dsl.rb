module Thespian
  class Dsl #:nodoc:
    attr_reader :receive_block
    attr_accessor :options

    def initialize
      @options = {}
    end

    def receive(&block)
      @receive_block = block
    end

  end
end
