module Dragonfly
  
  # HashWithName is like a normal hash, but treats
  # :name, :ext and :basename specially -
  # updating ext/basename also updates the name
  class HashWithName < Hash

    def name
      self[:name]
    end
    
    def basename
      self[:basename] || (File.basename(name, '.*') if name)
    end
    
    def ext
      self[:ext] || (File.extname(name)[/\.(.*)/, 1] if name)
    end

    def basename=(basename)
      self[:basename] = basename
      self[:name] = [basename, ext].compact.join('.')
    end
    
    def ext=(ext)
      self[:ext] = ext
      self[:name] = [basename, ext].compact.join('.')
    end
    
    def name=(name)
      self[:name] = name
    end
    
  end

end
