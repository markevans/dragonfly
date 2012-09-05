require 'pathname'
require 'yaml'

module Dragonfly
  module DataStorage
    class FileDataStore

      # Exceptions
      class UnableToFormUrl < RuntimeError; end

      class MetaStore
        def store(data_path, meta)
          File.open(meta_path(data_path), 'wb') do |f|
            f.write dump(meta)
          end
        end

        def retrieve(data_path)
          path = meta_path(data_path)
          File.open(path,'rb'){|f| load(f.read) } if File.exist?(path)
        end

        def destroy(path)
          FileUtils.rm_f meta_path(path)
        end

        private

        def meta_path(data_path)
          raise NotImplementedError
        end

        def dump(meta)
          raise NotImplementedError
        end

        def load(string)
          raise NotImplementedError
        end
      end

      class YAMLMetaStore < MetaStore
        def meta_path(data_path)
          "#{data_path}.meta.yml"
        end

        def dump(meta)
          YAML.dump(meta)
        end

        def load(string)
          YAML.load(string)
        end
      end
      
      class MarshalMetaStore < MetaStore
        def meta_path(data_path)
          "#{data_path}.meta"
        end
        
        def dump(meta)
          Marshal.dump(meta)
        end

        def load(string)
          Marshal.load(string)
        end
      end

      def initialize(opts={})
        self.root_path = opts[:root_path] || '/var/tmp/dragonfly'
        self.server_root = opts[:server_root]
        self.store_meta = opts[:store_meta]
        @meta_store = YAMLMetaStore.new
        @deprecated_meta_store = MarshalMetaStore.new
      end

      attr_writer :store_meta
      attr_reader :root_path, :server_root

      def root_path=(path)
        @root_path = path ? path.to_s : nil
      end
      
      def server_root=(path)
        @server_root = path ? path.to_s : nil
      end
      
      def store_meta?
        @store_meta != false # Default to true if not set
      end

      def store(temp_object, opts={})
        relative_path = if opts[:path]
          opts[:path]
        else
          filename = temp_object.name || 'file'
          relative_path = relative_path_for(filename)
        end

        begin
          path = absolute(relative_path)
          until !File.exist?(path)
            path = disambiguate(path)
          end
          temp_object.to_file(path).close
          meta_store.store(path, temp_object.meta) if store_meta?
        rescue Errno::EACCES => e
          raise UnableToStore, e.message
        end

        relative(path)
      end

      def retrieve(relative_path)
        validate_uid!(relative_path)
        path = absolute(relative_path)
        pathname = Pathname.new(path)
        raise DataNotFound, "couldn't find file #{path}" unless pathname.exist?
        meta = if store_meta?
          meta_store.retrieve(path) || deprecated_meta_store.retrieve(path) || {}
        else
          {}
        end
        [pathname, meta]
      end

      def destroy(relative_path)
        validate_uid!(relative_path)
        path = absolute(relative_path)
        FileUtils.rm path
        meta_store.destroy(path)
        purge_empty_directories(relative_path)
      rescue Errno::ENOENT => e
        raise DataNotFound, e.message
      end

      def url_for(relative_path, opts={})
        if server_root.nil?
          raise UnableToFormUrl, "you need to configure server_root for #{self.class.name} in order to form urls"
        else
          _, __, path = absolute(relative_path).partition(server_root)
          if path.empty?
            raise UnableToFormUrl, "couldn't form url for uid #{relative_path.inspect} with root_path #{root_path.inspect} and server_root #{server_root.inspect}"
          else
            path
          end
        end
      end

      def disambiguate(path)
        dirname = File.dirname(path)
        basename = File.basename(path, '.*')
        extname = File.extname(path)
        "#{dirname}/#{basename}_#{(Time.now.usec*10 + rand(100)).to_s(32)}#{extname}"
      end

      private

      attr_reader :meta_store, :deprecated_meta_store

      def absolute(relative_path)
        relative_path.to_s == '.' ? root_path : File.join(root_path, relative_path)
      end

      def relative(absolute_path)
        absolute_path[/^#{Regexp.escape root_path}\/?(.*)$/, 1]
      end

      def directory_empty?(path)
        Dir.entries(path) == ['.','..']
      end
      
      def root_path?(dir)
        root_path == dir
      end

      def relative_path_for(filename)
        time = Time.now
        msec = time.usec / 1000
        "#{time.strftime '%Y/%m/%d/%H_%M_%S'}_#{msec}_#{filename.gsub(/[^\w.]+/,'_')}"
      end

      def purge_empty_directories(path)
        containing_directory = Pathname.new(path).dirname
        containing_directory.ascend do |relative_dir|
          dir = absolute(relative_dir)
          FileUtils.rmdir dir if directory_empty?(dir) && !root_path?(dir)
        end
      end

      def validate_uid!(uid)
        raise BadUID, "tried to retrieve uid #{uid.inspect}" if uid.blank? || uid['../']
      end

    end

  end
end
