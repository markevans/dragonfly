require 'logger'

module Dragonfly
  module Loggable
    
    attr_writer :log
    
    def log
      @log ||= Logger.new(STDOUT)
    end
    
  end
end
