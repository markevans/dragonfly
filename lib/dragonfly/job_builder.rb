module Dragonfly
  class JobBuilder

    def initialize(&block)
      @block = block
    end

    def build(job, *args)
      evaluate_block(job, false, *args)
    end

    def build!(job, *args)
      evaluate_block(job, true, *args)
    end

    Job.step_names.each do |step|
      
      # fetch, process, etc.
      define_method step do |*args|
        if @perform_with_bangs
          @job.send("#{step}!", *args)
        else
          @job = @job.send(step, *args)
        end
      end
      
    end
    
    private
    
    def evaluate_block(job, perform_with_bangs, *args)
      @job = job
      @perform_with_bangs = perform_with_bangs
      instance_exec(*args, &@block)
      @job
    end

  end
end