module Dragonfly
  module Configurable

    # Exceptions
    class UnregisteredPlugin < RuntimeError; end

    class Configurer

      class << self
        def writer(*args)
          opts = args.last.is_a?(Hash) ? args.pop : {}
          names = args
          names.each do |name|
            define_method name do |value|
              if opts[:for]
                obj.send(opts[:for]).send("#{name}=", value)
              else
                obj.send("#{name}=", value)
              end
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
      
      def register_plugin(name, &block)
        registered_plugins[name] = block
      end
      
      def use(plugin, *args, &block)
        if plugin.is_a?(Symbol)
          raise(UnregisteredPlugin, "plugin #{plugin.inspect} is not registered") unless registered_plugins[plugin]
          plugin = registered_plugins[plugin].call
        end
        plugin.call(obj, *args)
        plugin.instance_eval(&block) if block
        plugin
      end
      
      private
      
      attr_reader :obj
      
      def registered_plugins
        @registered_plugins ||= {}
      end
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
