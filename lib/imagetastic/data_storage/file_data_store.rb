module Imagetastic::DataStorage

  class FileDataStore < DataStore

    IMAGE_STORE_ROOT = "/tmp/imagetastic"

    def store(data, name="image")

      storage_path = "#{IMAGE_STORE_ROOT}/#{Time.now.strftime '%Y/%m/%d/%H_%M_%S'}_#{name}"

      begin
        FileUtils.mkdir_p File.dirname(storage_path)
        File.open(storage_path, 'w') do |file|
          file.write(data)
        end
      rescue Errno::EACCES => e
        raise UnableToStore, e.message
      end
      
      storage_path
    end

    def retrieve(file_path)
      begin
        File.read(file_path)
      rescue Errno::ENOENT => e
        raise DataNotFound, e.message
      end
    end

  end

end
