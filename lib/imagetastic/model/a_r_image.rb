require 'active_record'

module Imagetastic
  module Model
    class ARImage

      def file=(temp_file)

        # The file object received is an ActionController::UploadedTempfile object
        # It has the following useful attributes:
        # size (in bytes), local_path (path to temp file on server), original_path (basename), content_type (MIME)

        raise ArgumentError, "The method 'file=' expects a file object - #{temp_file} was received instead" unless temp_file.is_a?(ActionController::UploadedTempfile)

        width, height = Imagetastic.image_analyser.get_dimensions(temp_file)

        # Save meta data
        self.size      = temp_file.size
        self.width     = width
        self.height    = height
        self.mime_type = temp_file.content_type

        # Save image itself
        Imagetastic.datastore.store(self, temp_file)

      end

    end
  end
end