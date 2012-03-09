module Dragonfly
  class JobEndpoint

    def initialize(job)
      @job = job
    end

    def call(env={})
      Response.new(job, env).to_response
    end

    attr_reader :job

    def inspect
      "<#{self.class.name} steps=#{job.steps} >"
    end

  end
end
