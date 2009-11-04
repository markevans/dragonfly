require 'mime/types'

module Dragonfly
  module MimeTypes

    class MimeTypeNotFound < StandardError; end

    class << self

      def mime_type_for(ext)
        ext = ext.to_s.sub(/^\./,'')
        mime_type = MIME::Types.type_for(ext).to_s
        raise_mime_type_not_found(mime_type) if mime_type.empty?
        mime_type
      end
    
      def extension_for(mime_type)
        known_mime_type = MIME::Types[mime_type].first
        raise_mime_type_not_found(mime_type) if known_mime_type.nil?
        known_mime_type.extensions.first
      end

      private
      
      def raise_mime_type_not_found(mime_type)
        raise MimeTypeNotFound, "Couldn't find the mime-type #{mime_type.inspect}. You can register mime-types using Dragonfly::MimeTypes.register"
      end
      
    end

  end
end