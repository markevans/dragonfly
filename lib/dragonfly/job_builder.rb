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

    def process(*args)
      if @perform_with_bangs
        @job.process!(*args)
      else
        @job = @job.process(*args)
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