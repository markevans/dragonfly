require 'stringio'
require 'tempfile'
require 'pathname'

module Dragonfly

  # A TempObject is used for HOLDING DATA.
  # It's the thing that is passed between the datastore, the processor and the encoder, and is useful
  # for separating how the data was created and how it is later accessed.
  #
  # You can initialize it various ways:
  #
  #   temp_object = Dragonfly::TempObject.new('this is the content')           # with a String
  #   temp_object = Dragonfly::TempObject.new(Pathname.new('path/to/content')) # with a Pathname
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

    include HasFilename

    # Exceptions
    class Closed < RuntimeError; end

    # Instance Methods

    def initialize(obj, meta={})
      if obj.is_a? TempObject
        @data = obj.get_data
        @tempfile = obj.get_tempfile
        @pathname = obj.get_pathname
      elsif obj.is_a? String
        @data = obj
      elsif obj.is_a? Tempfile
        @tempfile = obj
      elsif obj.is_a? File
        @pathname = Pathname.new(obj.path)
      elsif obj.is_a? Pathname
        @pathname = obj
      elsif obj.respond_to?(:tempfile)
        @tempfile = obj.tempfile
      elsif obj.respond_to?(:path) # e.g. Rack::Test::UploadedFile
        @pathname = Pathname.new(obj.path)
      else
        raise ArgumentError, "#{self.class.name} must be initialized with a String, a Pathname, a File, a Tempfile, another TempObject, something that responds to .tempfile, or something that responds to .path"
      end
      
      @tempfile.close if @tempfile

      # Original filename
      @original_filename = if obj.respond_to?(:original_filename)
        obj.original_filename
      elsif @pathname
        @pathname.basename.to_s
      end
      
      # Meta
      @meta = meta
      @meta[:name] ||= @original_filename if @original_filename
    end
    
    attr_reader :original_filename
    attr_accessor :meta
    
    def name
      meta[:name]
    end
    
    def name=(name)
      meta[:name] = name
    end

    def data
      raise Closed, "can't read data as TempObject has been closed" if closed?
      @data ||= file{|f| f.read }
    end

    def tempfile
      raise Closed, "can't read from tempfile as TempObject has been closed" if closed?
      @tempfile ||= begin
        case
        when @data
          @tempfile = new_tempfile(@data)
        when @pathname
          @tempfile = copy_to_tempfile(@pathname.expand_path)
        end
        @tempfile
      end
    end

    def file(&block)
      f = tempfile.open
      tempfile.binmode
      if block_given?
        ret = yield f
        tempfile.close unless tempfile.closed?
      else
        ret = f
      end
      ret
    end

    def path
      @pathname ? @pathname.expand_path.to_s : tempfile.path
    end

    def size
      @data ? @data.bytesize : File.size(path)
    end

    def each(&block)
      to_io do |io|
        while part = io.read(block_size)
          yield part
        end
      end
    end

    def to_file(path, opts={})
      mode = opts[:mode] || 0644
      prepare_path(path) unless opts[:mkdirs] == false
      if @data
        File.open(path, 'wb', mode){|f| f.write(@data) }
      else
        FileUtils.cp(self.path, path)
        File.chmod(mode, path)
      end
      File.new(path, 'rb')
    end

    def to_io(&block)
      @data ? StringIO.open(@data, 'rb', &block) : file(&block)
    end

    def close
      @tempfile.close! if @tempfile
      @data = nil
      @closed = true
    end

    def closed?
      !!@closed
    end

    def inspect
      content_string = case
      when @data
        data_string = size > 20 ? "#{@data[0..20]}..." : @data
        "data=#{data_string.inspect}"
      when @pathname then "pathname=#{@pathname.inspect}"
      when @tempfile then "tempfile=#{@tempfile.inspect}"
      end
      "<#{self.class.name} #{content_string} >"
    end

    def unique_id
      @unique_id ||= "#{object_id}#{rand(1000000)}"
    end

    protected

    # We don't use normal accessors here because #data etc. do more than just return the instance var
    def get_data
      @data
    end
    
    def get_pathname
      @pathname
    end
    
    def get_tempfile
      @tempfile
    end

    private

    def block_size
      8192
    end

    def copy_to_tempfile(path)
      tempfile = new_tempfile
      FileUtils.cp path, tempfile.path
      tempfile
    end

    def new_tempfile(content=nil)
      tempfile = ext ? Tempfile.new(['dragonfly', ".#{ext}"]) : Tempfile.new('dragonfly')
      tempfile.binmode
      tempfile.write(content) if content
      tempfile.close
      tempfile
    end

    def prepare_path(path)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
    end

  end
end
