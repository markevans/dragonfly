require 'rack'
require 'digest/sha1'

module Dragonfly
  class DosProtector

    DEFAULT_SHA_LENGTH = 16

    # Class methods
    class << self
      def required_params_for(path, secret, opts={})
        sha_length = opts[:sha_length] || DEFAULT_SHA_LENGTH
        {'s' => sha_for(path, secret, sha_length)}
      end

      def sha_for(path, secret, sha_length)
        Digest::SHA1.hexdigest("#{path}#{secret}")[0...sha_length]
      end
    end

    # Instance methods

    def initialize(app, secret, opts={})
      @app, @secret = app, secret
      @sha_length = opts.delete(:sha_length) || DEFAULT_SHA_LENGTH
      @constraints = opts
    end

    def call(env)
      request = Rack::Request.new(env)

      return app.call(env) unless matches_constraints?(request)

      case request.params['s']
      when nil, ''
        [400, {"Content-Type" => "text/plain"}, ["You need to give a SHA parameter"]]
      when sha_for(request.path)
        app.call(env)
      else
        [400, {"Content-Type" => "text/plain"}, ["The SHA parameter you gave is incorrect"]]
      end
    end

    private

    attr_reader :app, :secret, :sha_length, :constraints

    def sha_for(path)
      self.class.sha_for(path, secret, sha_length)
    end

    def matches_constraints?(request)
      constraints.each do |key, value|
        return false unless value === request.send(key)
      end
      true
    end

  end
end
