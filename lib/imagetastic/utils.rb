require 'mime/types'

module Imagetastic
  module Utils

    private

    def mime_type_from_extension(ext)
      MIME::Types.type_for(ext).to_s
    end
    
    def extension_from_mime_type(mime_type)
      MIME::Types[mime_type].first.extensions.first
    end

    # Annoyingly, the 'build_query' in Rack::Utils doesn't seem to work
    # properly for nested parameters/arrays
    # Taken from http://github.com/sinatra/sinatra/commit/52658061d1205753a8afd2801845a910a6c01ffd
    def build_query(value, prefix = nil)
      case value
      when Array
        value.map { |v|
          build_query(v, "#{prefix}[]")
        } * "&"
      when Hash
        value.map { |k, v|
          build_query(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
        } * "&"
      else
        "#{prefix}=#{escape(value)}"
      end
    end
    
    def file_extension(path)
      extension = path.sub(/^\//,'').split('.').last
    end

  end
end