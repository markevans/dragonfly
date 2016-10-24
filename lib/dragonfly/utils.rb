require 'tempfile'
require 'uri'
require 'rack'

module Dragonfly
  module Utils

    module_function

    def blank?(obj)
      obj.respond_to?(:empty?) ? obj.empty? : !obj
    end

    def new_tempfile(ext=nil, content=nil)
      tempfile = ext ? Tempfile.new(['dragonfly', ".#{ext}"]) : Tempfile.new('dragonfly')
      tempfile.binmode
      tempfile.write(content) if content
      tempfile.close
      tempfile
    end

    def symbolize_keys(hash)
      hash.inject({}) do |new_hash, (key, value)|
        new_hash[key.to_sym] = value
        new_hash
      end
    end

    def stringify_keys(hash)
      hash.inject({}) do |new_hash, (key, value)|
        new_hash[key.to_s] = value
        new_hash
      end
    end

    def uri_escape_segment(string)
      URI.encode_www_form_component(string).gsub('+','%20')
    end

    def uri_unescape(string)
      URI.unescape(string)
    end

  end
end
