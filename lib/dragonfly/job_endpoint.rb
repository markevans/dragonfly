module Dragonfly
  class JobEndpoint

    include Endpoint

    def initialize(job)
      @job = job
    end

    def call(env={})
      response_for_job(job, env)
    end

    attr_reader :job

  end
end
