require 'rbconfig'
require 'logger'

module Dragonfly
  class << self

    def app(name=nil)
      App.instance(name)
    end

    def [](name)
      App[name]
    end

    def running_on_windows?
      !!(RbConfig::CONFIG['host_os'] =~ %r!(msdos|mswin|djgpp|mingw)!)
    end

    # Logging
    def logger
      @logger = Logger.new('dragonfly.log') unless instance_variable_defined?(:@logger)
      @logger
    end
    attr_writer :logger

    [:debug, :warn, :info].each do |method|
      define_method method do |message|
        return unless logger
        logger.send(method, "DRAGONFLY: #{message}")
      end
    end

  end
end
