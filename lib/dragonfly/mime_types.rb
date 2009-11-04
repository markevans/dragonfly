require 'mime/types'

module Dragonfly
  module MimeTypes

    class << self

      def mime_type_for(ext)
        MIME::Types.type_for(ext).to_s
      end
    
      def extension_for(mime_type)
        MIME::Types[mime_type].first.extensions.first
      end

    end

  end
end