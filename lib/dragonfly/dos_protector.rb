require 'rack'
require 'digest/sha1'

module Dragonfly
  class DosProtector
    
    def initialize(app, secret, opts={})
      @app, @secret = app, secret
      @sha_length = opts[:sha_length] || 16
    end
    
    def call(env)
      request = Rack::Request.new(env)
      case request.params['s']
      when nil, ''
        [400, {"Content-Type" => "text/plain"}, ["You need to give a SHA parameter"]]
      when sha_for(request)
        app.call(env)
      else
        [400, {"Content-Type" => "text/plain"}, ["The SHA parameter you gave is incorrect"]]
      end
    end
    
    private
    
    attr_reader :app, :secret, :sha_length
    
    def sha_for(request)
      Digest::SHA1.hexdigest("#{request.path}#{secret}")[0...sha_length]
    end
    
  end
end
