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
      @parts = []
      instance_eval(&block)
    end
    
    attr_reader :parts
    
    def +(other_job)
      new_job = self.class.new{}
      new_job.parts = parts + other_job.parts
      new_job
    end
    
    protected
    
    attr_writer :parts
    
    private
    
    def process(name, *args)
      parts << Process.new(name, *args)
    end
    
    def encode(format, *args)
      parts << Encoding.new(format, *args)
    end
    
  end
end