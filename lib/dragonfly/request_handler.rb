require 'digest/sha1'
require 'forwardable'

module Dragonfly
  class RequestHandler
    
    # Exceptions
    class NotInitialized < StandardError; end
    class IncorrectSHA < RuntimeError; end
    class SHANotGiven < RuntimeError; end
    
    include Configurable

    configurable_attr :protect_from_dos_attacks, false
    configurable_attr :secret, 'This is a secret!'
    configurable_attr :sha_length, 16
    configurable_attr :path_prefix, ''

    extend Forwardable
    
    def_delegators :request, :path

    def init!(env)
      @request = Rack::Request.new(env)
    end

    def request
      @request || raise(NotInitialized, "You need to call init! to initialize the request")
    end
    
    def generate_sha
      Digest::SHA1.hexdigest("#{path}#{secret}")[0...sha_length]
    end
    
    private

  end
end
