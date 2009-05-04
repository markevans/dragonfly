module Imagetastic::DataStorage

  class FileDataStore < DataStore

    IMAGE_STORE_ROOT = "/tmp/imagetastic"

    def store(data, name="image")

      storage_path = "#{IMAGE_STORE_ROOT}/#{Time.now.strftime '%Y/%m/%d/%H_%M_%S'}_#{name}"

      FileUtils.mkdir_p File.dirname(storage_path)
      File.open(storage_path, 'w') do |file|
        file.write(data)
      end
      
      storage_path
    end

    def retrieve(image)
      File.read(image.file_path)
    end

  end

end
