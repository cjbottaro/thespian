module Thespian
  class Dsl #:nodoc:
    attr_reader :receive_block

    def receive(&block)
      @receive_block = block
    end

  end
end
