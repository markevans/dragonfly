module Dragonfly
  class JobManager
    
    class JobBuilder
      def initialize(args, definition_proc)
        @job = Job.new
        instance_exec(*args, &definition_proc)
      end
      attr_reader :job
      private
      def process(name, *args)
        @job.add_process name, *args
      end
      def encode(format, *args)
        @job.add_encoding format, *args
      end
    end
    
    class JobDefinition
      def initialize(arg_matchers, definition_proc)
        @arg_matchers, @definition_proc = arg_matchers, definition_proc
      end
      
      def create_job(args)
        JobBuilder.new(args, definition_proc).job
      end
      
      def matches?(args)
        arg_matchers.length == args.length &&
          ![arg_matchers, args].transpose.map{|(matcher, arg)|
            matcher === arg
          }.include?(false)
      end
      
      private
      attr_reader :arg_matchers, :definition_proc
    end
    
    def initialize
      @job_definitions = []
    end
    
    def define_job(*arg_matchers, &definition_proc)
      job_definitions << JobDefinition.new(arg_matchers, definition_proc)
    end
    
    def job_for(*args)
      job_definitions.each do |jd|
        return jd.create_job(args) if jd.matches?(args)
      end
      nil
    end
    
    private
    attr_reader :job_definitions
  end
end
