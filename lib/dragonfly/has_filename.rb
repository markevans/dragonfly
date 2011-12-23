module Dragonfly
  # Convenience methods for setting basename and extension
  # Including class needs to define a 'name' accessor
  # which is assumed to hold a filename-style string
  module HasFilename
    
    def basename
      File.basename(name, '.*') if name
    end
    
    def basename=(basename)
      self.name = [basename, ext].compact.join('.')
    end

    def ext
      File.extname(name)[/\.(.*)/, 1] if name
    end
    
    def ext=(ext)
      self.name = [(basename || 'file'), ext].join('.')
    end
    
  end
end
