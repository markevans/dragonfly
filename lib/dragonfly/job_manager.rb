module Dragonfly
  class JobManager
    
    # Exceptions
    class JobNotFound < RuntimeError; end
    
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
      def initialize(name, definition_proc)
        @name, @definition_proc = name, definition_proc
      end
      attr_reader :name
      def create_job(args)
        JobBuilder.new(args, definition_proc).job
      end
      private
      attr_reader :definition_proc
    end
    
    def initialize
      @job_definitions = {}
    end
    
    def define_job(name, &definition_proc)
      job_definitions[name] = JobDefinition.new(name, definition_proc)
    end
    
    def job_for(name, *args)
      job_definition = job_definitions[name]
      if job_definition
        job_definition.create_job(args)
      else
        raise JobNotFound, "No job was found with name '#{name}'"
      end
    end
    
    private
    attr_reader :job_definitions
  end
end
