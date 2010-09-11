module Dragonfly
  class JobEndpoint

    def initialize(job)
      @job = job
    end

    def call(env={})
      Response.new(job, env).to_response
    end

    attr_reader :job

  end
end
