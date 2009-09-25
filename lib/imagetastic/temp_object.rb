require 'tempfile'

module Imagetastic
  class TempObject
    
    def self.from_file(path)
      new(File.new(path, 'r'))
    end
    
    def initialize(obj)
      case obj
      when String
        @initialized_data = obj
      when Tempfile
        @initialized_tempfile = obj
      when File
        @initialized_file = obj
      else
        raise ArgumentError, "TempObject must be initialized with a String, a File or a Tempfile"
      end
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
    
    attr_reader :initialized_data, :initialized_tempfile, :initialized_file
    
  end
end