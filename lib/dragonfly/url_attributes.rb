module Dragonfly
  
  # UrlAttributes is like a normal hash, but treats
  # :name, :ext and :basename specially -
  # updating ext/basename also updates the name
  class UrlAttributes < Hash

    SPECIAL_KEYS = [:name, :basename, :ext]

    include HasFilename

    def name
      self[:name]
    end
    
    def name=(name)
      self[:name] = name
    end
    
    def slice(*keys)
      keys.inject({}) do |hash, key|
        key = key.to_sym
        hash[key] = SPECIAL_KEYS.include?(key) ? send(key) : self[key]
        hash
      end
    end
    
  end

end
