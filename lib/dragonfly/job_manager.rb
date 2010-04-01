module Dragonfly
  class JobManager
    
    # Exceptions
    class JobNotFound < RuntimeError; end
    
    class JobBuilder
      def initialize(definition_proc, job_manager, opts={})
        @job_manager = job_manager
        @built_job = Job.new
        @opts = opts
        instance_eval(&definition_proc)
      end
      attr_reader :built_job, :opts
      private
      def process(name, *args)
        built_job.add_process name, *args
      end
      def encode(format, *args)
        built_job.add_encoding format, *args
      end
      def job(name, *args)
        @built_job += @job_manager.job_for(name, *args)
      end
    end
    
    class JobDefinition
      def initialize(name, definition_proc, job_manager)
        @name, @definition_proc, @job_manager = name, definition_proc, job_manager
      end
      attr_reader :name
      def create_job(opts={})
        JobBuilder.new(definition_proc, job_manager, opts).built_job
      end
      private
      attr_reader :definition_proc, :job_manager
    end
    
    def initialize
      @job_definitions = {}
    end
    
    def define_job(name, &definition_proc)
      job_definitions[name] = JobDefinition.new(name, definition_proc, self)
    end
    
    def job_for(name, opts={})
      job_definition = job_definitions[name]
      if job_definition
        job_definition.create_job(opts)
      else
        raise JobNotFound, "No job was found with name '#{name}'"
      end
    end
    
    private
    attr_reader :job_definitions
  end
end
