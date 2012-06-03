module Dragonfly
  module Configurable

    class Configurer

      class << self
        def writer(*names)
          names.each do |name|
            define_method name do |value|
              obj.send("#{name}=", value)
            end
          end
        end
        
        def meth(*names)
          names.each do |name|
            define_method name do |*args, &block|
              obj.send(name, *args, &block)
            end
          end
        end
      end

      def initialize(&block)
        (class << self; self; end).class_eval(&block)
      end

      def configure(obj, &block)
        @obj = obj
        instance_eval(&block)
        @obj = nil
      end
      
      attr_reader :obj
    end
    
    #######

    def setup_config(&setup_block)
      self.configurer = Configurer.new(&setup_block)
      class_eval do
        def configure(&block)
          self.class.configurer.configure(self, &block)
          self
        end
      end
    end
    
    attr_accessor :configurer

  end
end
