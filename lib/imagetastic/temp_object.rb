require 'tempfile'

module Imagetastic
  class TempObject
  
    # Class methods
    
    def self.from_file(path)
      new(File.new(path, 'r'))
    end
    
    # Instance Methods
    
    def initialize(obj)
      initialize_from_object!(obj)
    end
    
    def modify_self!(obj)
      reset!
      initialize_from_object!(obj)
      self
    end
    
    def data
      @data ||= initialized_data || file.open.read
    end

    def tempfile
      if @tempfile
        @tempfile
      elsif initialized_tempfile
        @tempfile = initialized_tempfile
      elsif initialized_data
        tempfile = Tempfile.new('imagetastic')
        tempfile.write(initialized_data)
        tempfile.close
        @tempfile = tempfile
      elsif initialized_file
        # Get the path for a new tempfile
        tempfile = Tempfile.new('imagetastic')
        tempfile.close
        FileUtils.cp File.expand_path(initialized_file.path), tempfile.path
        @tempfile = tempfile
      end
    end
    
    alias_method :file, :tempfile
    
    def path
      tempfile.path
    end
    
    def size
      if initialized_data
        initialized_data.size
      else
        File.size(path)
      end
    end
    
    def each(&block)
      if initialized_data
        string_io = StringIO.new(initialized_data)
        while part = string_io.read(8192)
          yield part
        end
      else
        tempfile.open
        while part = tempfile.read(8192)
          yield part
        end
        tempfile.close
      end
    end
    
    private
    
    attr_accessor :initialized_data, :initialized_tempfile, :initialized_file
    
    def reset!
      instance_variables.each do |var|
        instance_variable_set(var, nil)
      end
    end
    
    def initialize_from_object!(obj)
      case obj
      when String
        @initialized_data = obj
      when Tempfile
        @initialized_tempfile = obj
      when File
        @initialized_file = obj
      else
        raise ArgumentError, "#{self.class.name} must be initialized with a String, a File or a Tempfile"
      end
    end
    
  end
end