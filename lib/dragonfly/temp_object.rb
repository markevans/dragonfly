require 'tempfile'

module Dragonfly
  class TempObject
  
    # Instance Methods
    
    def initialize(obj)
      initialize_from_object!(obj)
    end
    
    attr_accessor :name
    
    def basename
      name.sub(/\..*?$/, '') if name
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
        tempfile = Tempfile.new('dragonfly')
        tempfile.write(initialized_data)
        tempfile.close
        @tempfile = tempfile
      elsif initialized_file
        @tempfile = copy_to_tempfile(initialized_file)
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
    
    protected
    
    attr_accessor :initialized_data, :initialized_tempfile, :initialized_file
    
    private
    
    def reset!
      instance_variables.each do |var|
        instance_variable_set(var, nil)
      end
    end
    
    def initialize_from_object!(obj)
      case obj
      when TempObject
        @initialized_data = obj.initialized_data
        @initialized_tempfile = copy_to_tempfile(obj.initialized_tempfile) if obj.initialized_tempfile
        @initialized_file = obj.initialized_file
      when String
        @initialized_data = obj
      when Tempfile
        @initialized_tempfile = obj
      when File
        @initialized_file = obj
      else
        raise ArgumentError, "#{self.class.name} must be initialized with a String, a File or a Tempfile"
      end
      self.name = obj.original_filename if obj.respond_to?(:original_filename)
    end
    
    def copy_to_tempfile(file)
      tempfile = Tempfile.new('dragonfly')
      tempfile.close
      FileUtils.cp File.expand_path(file.path), tempfile.path
      tempfile
    end
    
  end
end