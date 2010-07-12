module Dragonfly
  class JobEndpoint
    
    include Endpoint

    def initialize(job)
      @job = job
    end

    def call(env=nil)
      response_for_job(job)
    end
    
    attr_reader :job

  end
end
