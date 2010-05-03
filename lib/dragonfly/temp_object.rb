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
    
    def initialize(obj)
      initialize_from_object!(obj)
    end
    
    def modify_self!(obj)
      unless obj == self
        reset!
        initialize_from_object!(obj)
      end
      self
    end
    
    def data
      @data ||= initialized_data || file.read
    end

    def tempfile
      @tempfile ||= begin
        if initialized_tempfile
          @tempfile = initialized_tempfile
        elsif initialized_data
          @tempfile = Tempfile.new('dragonfly')
          @tempfile.write(initialized_data)
        elsif initialized_file
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
    
    attr_writer :name
    
    def name
      @name unless @name.blank?
    end
    
    def basename
      return unless name
      name.sub(/\.[^.]+$/,'')
    end
    
    def ext
      return unless name
      bits = name.split('.')
      bits.last if bits.size > 1
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

    protected
    
    attr_accessor :initialized_data, :initialized_tempfile, :initialized_file
    
    private
    
    def reset!
      @data = @tempfile = @initialized_data = @initialized_file = @initialized_tempfile = nil
    end
    
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
    
    def block_size
      self.class.block_size
    end
    
    def copy_to_tempfile(path)
      tempfile = Tempfile.new('dragonfly')
      FileUtils.cp File.expand_path(path), tempfile.path
      tempfile
    end
    
  end
end