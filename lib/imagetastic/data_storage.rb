module Imagetastic
  module DataStorage

    extend HelperMethods

    self.autoload_files_in_dir self, "#{File.dirname(__FILE__)}/data_storage"

  end
end
