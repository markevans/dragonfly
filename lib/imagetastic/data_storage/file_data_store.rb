module Imagetastic::DataStorage

  class FileDataStore < DataStore

    IMAGE_STORE_ROOT = "#{RAILS_ROOT}/tmp/imagetastic"

    def store(image, file)

      storage_dir      = "#{IMAGE_STORE_ROOT}"
      storage_filename = "#{Time.now.strftime '%Y_%m_%d_%H_%M_%S'}_#{file.original_path}"
      storage_path     = "#{storage_dir}/#{storage_filename}"

      FileUtils.mkdir_p(storage_dir)
      File.open(storage_path, 'w') do |new_file|
        file.rewind
        new_file.write(file.read)
      end

      image.file_path = storage_path
    end

    def retrieve(image)
      File.read(image.file_path)
    end

  end

end
