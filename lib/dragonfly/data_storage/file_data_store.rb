require 'pathname'

module Dragonfly
  module DataStorage

    class FileDataStore < Base

      include Configurable
    
      configurable_attr :root_path, '/var/tmp/dragonfly'

      def store(temp_object)
        filename = temp_object.name || 'file'

        relative_path = relative_storage_path(filename)
        begin
          while File.exist?(storage_path = absolute_storage_path(relative_path))
            filename = disambiguate(filename)
            relative_path = relative_storage_path(filename)
          end
          storage_dir = File.dirname(storage_path)
          FileUtils.mkdir_p(storage_dir) unless File.exist?(storage_dir)
          FileUtils.cp temp_object.path, storage_path
        rescue Errno::EACCES => e
          raise UnableToStore, e.message
        end
      
        relative_path
      end

      def retrieve(relative_path)
        File.new(absolute_storage_path(relative_path))
      rescue Errno::ENOENT => e
        raise DataNotFound, e.message
      end

      def destroy(relative_path)
        FileUtils.rm absolute_storage_path(relative_path)
        containing_directory = Pathname.new(relative_path).dirname
        containing_directory.ascend do |relative_dir|
          dir = absolute_storage_path(relative_dir)
          FileUtils.rmdir dir if directory_empty?(dir)
        end
      rescue Errno::ENOENT => e
        raise DataNotFound, e.message
      end

      def disambiguate(filename)
        basename = File.basename(filename, '.*')
        extname = File.extname(filename)
        "#{basename}_#{Time.now.usec.to_s(32)}#{extname}"
      end

      private

      def relative_storage_path(filename)
        "#{Time.now.strftime '%Y/%m/%d'}/#{filename}"
      end
      
      def absolute_storage_path(relative_path)
        File.join(root_path, relative_path)
      end

      def directory_empty?(path)
        Dir.entries(path) == ['.','..']
      end

    end

  end
end
