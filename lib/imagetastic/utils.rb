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
    
    def file_extension(path)
      extension = path.sub(/^\//,'').split('.').last
    end

  end
end