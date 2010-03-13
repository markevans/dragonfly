module Dragonfly
  class Job
    
    # Processing job part
    class Process
      def initialize(name, *args)
        @name, @args = name, args
      end
      attr_reader :name, :args
    end
    
    # Encoding job part
    class Encoding
      def initialize(format, *args)
        @format, @args = format, args
      end
      attr_reader :format, :args
    end
    
    def initialize(&block)
      instance_eval(&block)
    end
    
    def parts
      @parts ||= []
    end
    
    private
    
    def process(name, *args)
      parts << Process.new(name, *args)
    end
    
    def encode(format, *args)
      parts << Encoding.new(format, *args)
    end
    
  end
end