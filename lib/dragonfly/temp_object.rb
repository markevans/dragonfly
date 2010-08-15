require 'stringio'
require 'tempfile'

module Dragonfly

  # A TempObject is used for HOLDING DATA.
  # It's the thing that is passed between the datastore, the processor and the encoder, and is useful
  # for separating how the data was created and how it is later accessed.
  #
  # You can initialize it various ways:
  #
  #   temp_object = Dragonfly::TempObject.new('this is the content')           # with a String
  #   temp_object = Dragonfly::TempObject.new(File.new('path/to/content'))     # with a File
  #   temp_object = Dragonfly::TempObject.new(some_tempfile)                   # with a Tempfile
  #   temp_object = Dragonfly::TempObject.new(some_other_temp_object)          # with another TempObject
  #
  # However, no matter how it was initialized, you can always access the data a number of ways:
  #
  #   temp_object.data      # returns a data string
  #   temp_object.file      # returns a file object holding the data
  #   temp_object.path      # returns a path for the file
  #
  # The data/file are created lazily, something which you may wish to take advantage of.
  #
  # For example, if a TempObject is initialized with a file, and temp_object.data is never called, then
  # the data string will never be loaded into memory.
  #
  # Conversely, if the TempObject is initialized with a data string, and neither temp_object.file nor temp_object.path
  # are ever called, then the filesystem will never be hit.
  #
  class TempObject

    # Class configuration
    class << self

      include Configurable
      configurable_attr :block_size, 8192

    end

    # Instance Methods

    def initialize(obj, opts={})
      initialize_from_object!(obj)
      validate_options!(opts)
      extract_attributes_from(opts)
    end

    def data
      @data ||= initialized_data || file.read
    end

    def tempfile
      @tempfile ||= begin
        case initialized_with
        when :tempfile
          @tempfile = initialized_tempfile
        when :data
          @tempfile = Tempfile.new('dragonfly')
          @tempfile.write(initialized_data)
        when :file
          @tempfile = copy_to_tempfile(initialized_file.path)
        end
        @tempfile.close
        @tempfile
      end
    end

    def file(&block)
      f = tempfile.open
      if block_given?
        ret = yield f
        f.close
      else
        ret = f
      end
      ret
    end

    def path
      tempfile.path
    end

    def size
      if initialized_data
        initialized_data.bytesize
      else
        File.size(path)
      end
    end

    attr_reader :name, :format
    alias _format format

    def meta
      @meta ||= {}
    end

    def basename
      File.basename(name, '.*') if name
    end

    def ext
      File.extname(name)[/\.(.*)/, 1] if name
    end

    def each(&block)
      to_io do |io|
        while part = io.read(block_size)
          yield part
        end
      end
    end

    def to_file(path)
      if initialized_data
        File.open(path, 'w'){|f| f.write(initialized_data) }
      else
        FileUtils.cp(self.path, path)
      end
      File.new(path)
    end

    def to_io(&block)
      if initialized_data
        StringIO.open(initialized_data, &block)
      else
        file(&block)
      end
    end

    def attributes
      {
        :name => name,
        :meta => meta,
        :format => format
      }
    end

    def extract_attributes_from(hash)
      self.name   = hash.delete(:name)   unless hash[:name].blank?
      self.meta   = hash.delete(:meta)   unless hash[:meta].blank?
      self.format = hash.delete(:format) unless hash[:format].blank?
    end

    def inspect
      content_string = case initialized_with
      when :data
        data_string = size > 20 ? "#{initialized_data[0..20]}..." : initialized_data
        "data=#{data_string.inspect}"
      when :file then "file=#{initialized_file.inspect}"
      when :tempfile then "tempfile=#{initialized_tempfile.inspect}"
      end
      to_s.sub(/>$/, " #{content_string}, @meta=#{@meta.inspect}, @name=#{@name.inspect} >")
    end

    protected

    attr_accessor :initialized_data, :initialized_tempfile, :initialized_file

    private

    attr_writer :name, :meta, :format

    def initialize_from_object!(obj)
      case obj
      when TempObject
        @initialized_data = obj.initialized_data
        @initialized_tempfile = copy_to_tempfile(obj.initialized_tempfile.path) if obj.initialized_tempfile
        @initialized_file = obj.initialized_file
      when String
        @initialized_data = obj
      when Tempfile
        @initialized_tempfile = obj
      when File
        @initialized_file = obj
        self.name = File.basename(obj.path)
      else
        raise ArgumentError, "#{self.class.name} must be initialized with a String, a File, a Tempfile, or another TempObject"
      end
      self.name = obj.original_filename if obj.respond_to?(:original_filename)
    end

    def initialized_with
      if initialized_tempfile
        :tempfile
      elsif initialized_data
        :data
      elsif initialized_file
        :file
      end
    end

    def block_size
      self.class.block_size
    end

    def copy_to_tempfile(path)
      tempfile = Tempfile.new('dragonfly')
      FileUtils.cp File.expand_path(path), tempfile.path
      tempfile
    end

    def validate_options!(opts)
      valid_keys = [:name, :meta, :format]
      invalid_keys = opts.keys - valid_keys
      raise ArgumentError, "Unrecognised options #{invalid_keys.inspect}" if invalid_keys.any?
    end

  end
end