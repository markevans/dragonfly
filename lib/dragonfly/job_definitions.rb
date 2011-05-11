module Dragonfly
  class JobDefinitions < Module

    def initialize
      @job_definitions = {}
    end

    def add(name, &definition_proc)
      job_definitions[name] = JobBuilder.new(&definition_proc)
      jd = job_definitions # Needed because we're about to change 'self'
      
      define_method name do |*args|
        jd[name].build(self, *args)
      end
      
      define_method "#{name}!" do |*args|
        jd[name].build!(self, *args)
      end
    end
    
    def definition_names
      job_definitions.keys
    end

    private

    attr_reader :job_definitions

  end
end
