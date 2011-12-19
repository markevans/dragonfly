module Dragonfly
  
  # HashWithName is like a normal hash, but treats
  # :name, :ext and :basename specially -
  # updating ext/basename also updates the name
  class HashWithName < Hash
    
    def self.[](hash)
      new_hash = super
      new_hash[:name] = hash[:name] if hash[:name] # Make sure the name= method gets called
      new_hash
    end
    
    def [](key)
      [:name, :basename, :ext].include?(key) ? send(key) : super
    end

    def []=(key, value)
      [:name, :basename, :ext].include?(key) ? send("#{key}=", value) : super
    end
    
    attr_accessor :basename, :ext
    
    def name
      [basename, ext].compact.join('.')
    end
    
    def name=(name)
      self.basename, self.ext = if name.nil?
        [nil, nil]
      else
        parts = name.split('.')
        if parts.length == 1
          [name, nil]
        else
          [parts[0...-1].join('.'), parts.last]
        end
      end
      name
    end
    
  end

end
