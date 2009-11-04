require 'mime/types'

module Dragonfly
  module MimeTypes

    class MimeTypeNotFound < StandardError; end

    class << self

      def mime_type_for(ext)
        ext = normalize_extension(ext)
        mime_type = custom_mime_types.index(ext) || MIME::Types.type_for(ext).first.to_s
        raise_mime_type_not_found("Couldn't find the mime type for the extension #{ext.inspect}") if mime_type.blank?
        mime_type
      end
    
      def extension_for(mime_type)
        ext = custom_mime_types[mime_type] ||
          MIME::Types[mime_type].first && MIME::Types[mime_type].first.extensions.first
        raise_mime_type_not_found("Couldn't find the mime type #{mime_type.inspect}") if ext.blank?
        ext
      end
      
      def register(mime_type, file_extension)
        custom_mime_types[mime_type] = normalize_extension(file_extension)
      end

      def clear_custom_mime_types!
        self.custom_mime_types = {}
      end

      private
      
      def raise_mime_type_not_found(message)
        raise MimeTypeNotFound, "#{message} - you can register mime-types using Dragonfly::MimeTypes.register"
      end
      
      def custom_mime_types
        @custom_mime_types ||= {}
      end
      
      attr_writer :custom_mime_types
      
      def normalize_extension(ext)
        ext.to_s.sub(/^\./,'')
      end
      
    end

  end
end