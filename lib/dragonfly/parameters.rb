require 'digest/sha1'

module Dragonfly
  class Parameters
    
    def self.from_url(path, query_string, route)
      params = new
      attrs = route.parse_url(path, query_string)
      %w(uid job sha).each do |meth|
        params.send("#{meth}=", attrs[meth])
      end
      params
    end
    
    def initialize(uid=nil, job=nil)
      @uid = uid
      @job_name, *@job_args = job unless job.blank?
    end
    
    attr_accessor :uid, :sha
    attr_reader :job_name, :job_args
    
    def job
      Serializer.marshal_encode([@job_name, *@job_args]) if @job_name
    end
    
    def job=(encoded_job)
      @job_name, *@job_args = Serializer.marshal_decode(encoded_job) if encoded_job
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
    
    def to_url(route)
      route
    end
  end
end
