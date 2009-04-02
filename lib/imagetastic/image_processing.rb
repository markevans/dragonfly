module Imagetastic
  module ImageProcessing

    extend HelperMethods

    autoload_files_in_dir self, "#{File.dirname(__FILE__)}/image_processing"

  end
end
