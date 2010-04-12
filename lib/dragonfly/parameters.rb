require 'digest/sha1'

module Dragonfly
  class Parameters
    
    attr_accessor :uid, :sha, :job_name, :job_opts
    
    def job
      Serializer.marshal_encode([@job_name, @job_opts]) if @job_name
    end
    
    def job=(encoded_job)
      @job_name, @job_opts = Serializer.marshal_decode(encoded_job) if encoded_job
    end
    
    def generate_sha!(secret, length)
      self.sha = generate_sha(secret, length)
    end
    
    def generate_sha(secret, length)
      Digest::SHA1.hexdigest("#{uid}#{job}#{secret}")[0...length]
    end
    
    def unique_signature
      generate_sha('I like cheese', 10)
    end
    
  end
end
