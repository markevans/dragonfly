module Dragonfly
  class JobDefinitions < Module

    class JobBuilder

      Job.step_names.each do |step|
        define_method step do |*args|
          job.send(step, *args)
        end
      end

    end
    
    class JobDefinition
      def initialize(name, definition_proc, job_definitions)
        @name, @definition_proc, @job_definitions = name, definition_proc, job_definitions
      end
      attr_reader :name
      def create_job(opts={})
        JobBuilder.new(definition_proc, job_definitions, opts).built_job
      end
      private
      attr_reader :definition_proc, :job_definitions
    end
    
    def initialize
      @job_definitions = {}
    end
    
    def add(name, &definition_proc)
      job_definitions[name] = JobDefinition.new(name, definition_proc, self)
      define_method name do |*args|
        named_job name, *args
      end
    end
    
    def named_job(name, *args)
    end
    
    private
    attr_reader :job_definitions
  end
end
