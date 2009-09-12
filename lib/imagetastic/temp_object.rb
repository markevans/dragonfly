require 'tempfile'

module Imagetastic
  class TempObject
    
    def self.from_file(path)
      new(File.new(path, 'r'))
    end
    
    def initialize(obj)
      case obj
      when String
        @data = obj
      when Tempfile
        @tempfile = obj
      when File
        @file = obj
      else
        raise ArgumentError, "TempObject must be initialized with a String, a File or a Tempfile"
      end
    end
    
    def data
      if @data
        @data
      else
        @data = file.open.read
      end
    end

    def tempfile
      if @tempfile
        @tempfile
      elsif @data
        tempfile = Tempfile.new('imagetastic')
        tempfile.write(@data)
        tempfile.close
        @tempfile = tempfile
      elsif @file
        # Get the path for a new tempfile
        tempfile = Tempfile.new('imagetastic')
        tempfile.close
        FileUtils.cp File.expand_path(@file.path), tempfile.path
        @tempfile = tempfile
      end
    end
    
    alias_method :file, :tempfile
    
    def path
      tempfile.path
    end
    
    def each(&block)
      tempfile.open
      while part = tempfile.read(8192)
        yield part
      end
      tempfile.close
    end
    
  end
end