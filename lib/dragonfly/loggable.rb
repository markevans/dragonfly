require 'logger'

module Dragonfly
  module Loggable

    def log
      case @log_object
      when nil
        @log_object = Logger.new($stdout)
      when Proc
        @log_object[]
      when Logger
        @log_object
      end
    end

    def log=(object)
      @log_object = object
    end
    
    attr_reader :log_object

    def use_same_log_as(object)
      self.log = proc{ object.log }
    end

  end
end
