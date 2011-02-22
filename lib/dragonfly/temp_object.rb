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
      opts ||= {} # in case it's nil
      initialize_from_object!(obj)
      validate_options!(opts)
      extract_attributes_from(opts)
    end

    def data
      @data ||= file{|f| f.read }
    end

    def tempfile
      @tempfile ||= begin
        case
        when @data
          @tempfile = new_tempfile(@data)
        when @file
          @tempfile = copy_to_tempfile(@file.path)
        end
        @tempfile
      end
    end

    def file(&block)
      f = tempfile.open
      tempfile.binmode
      if block_given?
        ret = yield f
        tempfile.close
      else
        ret = f
      end
      ret
    end

    def path
      @file ? File.expand_path(@file.path) : tempfile.path
    end

    def size
      @data ? @data.bytesize : File.size(path)
    end

    attr_accessor :name, :format
    attr_writer :meta

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
      if @data
        File.open(path, 'wb'){|f| f.write(@data) }
      else
        FileUtils.cp(self.path, path)
      end
      File.new(path, 'rb')
    end

    def to_io(&block)
      @data ? StringIO.open(@data, 'rb', &block) : file(&block)
    end

    def attributes
      {
        :name => name,
        :meta => meta,
        :format => format
      }
    end

    def extract_attributes_from(hash)
      self.name   = hash.delete(:name)     unless hash[:name].blank?
      self.format = hash.delete(:format)   unless hash[:format].blank?
      self.meta.merge!(hash.delete(:meta)) unless hash[:meta].blank?
    end

    def inspect
      content_string = case
      when @data
        data_string = size > 20 ? "#{@data[0..20]}..." : @data
        "data=#{data_string.inspect}"
      when @file then "file=#{@file.inspect}"
      when @tempfile then "tempfile=#{@tempfile.inspect}"
      end
      to_s.sub(/>$/, " #{content_string}, @meta=#{@meta.inspect}, @name=#{@name.inspect} >")
    end

    protected

    # We don't use normal accessors here because #data etc. do more than just return the instance var
    def get_data
      @data
    end
    
    def get_file
      @file
    end
    
    def get_tempfile
      @tempfile
    end

    private

    def initialize_from_object!(obj)
      if obj.is_a? TempObject
        @data = obj.get_data
        @tempfile = obj.get_tempfile
        @file = obj.get_file
      elsif obj.is_a? String
        @data = obj
      elsif obj.is_a? Tempfile
        @tempfile = obj
      elsif obj.is_a? File
        @file = obj
        self.name = File.basename(obj.path)
      elsif obj.respond_to?(:tempfile)
        @tempfile = obj.tempfile
      else
        raise ArgumentError, "#{self.class.name} must be initialized with a String, a File, a Tempfile, another TempObject, or something that responds to .tempfile"
      end
      @tempfile.close if @tempfile
      self.name = obj.original_filename if obj.respond_to?(:original_filename)
    end

    def block_size
      self.class.block_size
    end

    def copy_to_tempfile(path)
      tempfile = new_tempfile
      FileUtils.cp File.expand_path(path), tempfile.path
      tempfile
    end

    def validate_options!(opts)
      valid_keys = [:name, :meta, :format]
      invalid_keys = opts.keys - valid_keys
      raise ArgumentError, "Unrecognised options #{invalid_keys.inspect}" if invalid_keys.any?
    end

    def new_tempfile(content=nil)
      tempfile = Tempfile.new('dragonfly')
      tempfile.binmode
      tempfile.write(content) if content
      tempfile.close
      tempfile
    end

  end
end