# encoding: utf-8
require 'base64'
require 'multi_json'

module Dragonfly
  module Serializer

    # Exceptions
    class BadString < RuntimeError; end
    class MaliciousString < RuntimeError; end

    extend self # So we can do Serializer.b64_encode, etc.

    def b64_encode(string)
      Base64.encode64(string).tr("\n=",'')
    end

    def b64_decode(string)
      padding_length = string.length % 4
      string = string.tr('~', '/')
      Base64.decode64(string + '=' * padding_length)
    end

    def marshal_encode(object)
      b64_encode(Marshal.dump(object))
    end

    def marshal_decode(string, opts={})
      marshal_string = b64_decode(string)
      raise MaliciousString, "potentially malicious marshal string #{marshal_string.inspect}" if opts[:check_malicious] && marshal_string[/@[a-z_]/i]
      Marshal.load(marshal_string)
    rescue TypeError, ArgumentError => e
      raise BadString, "couldn't decode #{string} - got #{e}"
    end

    def json_encode(object)
      b64_encode(MultiJson.encode(object))
    end

    def json_decode(string, opts={})
      MultiJson.decode(b64_decode(string), :symbolize_keys => opts[:symbolize_keys])
    rescue MultiJson::DecodeError => e
      raise BadString, "couldn't decode #{string} - got #{e}"
    end

  end
end
