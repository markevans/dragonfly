module Dragonfly
  class SimpleEndpoint
    
    include Endpoint

    def initialize(job)
      @job = job
    end

    def call(env)
      response_for_job(@job)
    end

  end
end
