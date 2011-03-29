module Dragonfly
  module ActiveModelExtensions
    class AttachmentSpec
      
      class ConfigProxy
        
        def initialize(spec, block)
          @spec = spec
          instance_eval(&block)
        end
        
        private
        
        attr_reader :spec
        
        def after_assign(*callbacks, &block)
          add_callbacks(:after_assign, *callbacks, &block)
        end
        
        def after_unassign(*callbacks, &block)
          add_callbacks(:after_unassign, *callbacks, &block)
        end
        
        def copy_to(accessor, &block)
          after_assign do |a|
            self.send "#{accessor}=", (block_given? ? instance_exec(a, &block) : a)
          end
          after_unassign{|a| self.send("#{accessor}=", nil) }
        end
        
        private
        
        def add_callbacks(name, *callbacks, &block)
          if block_given?
            spec.callbacks[name] << block
          else
            spec.callbacks[name].push(*callbacks)
          end
        end
        
      end
      
      def initialize(attribute, app, &block)
        @attribute, @app = attribute, app
        ConfigProxy.new(self, block) if block_given?
      end

      attr_reader :attribute, :app

      def new_attachment(model)
        app.attachment_class.new(self, model)
      end
      
      def callbacks
        @callbacks ||= Hash.new{|h,k| h[k] = [] }
      end
      
      def run_callbacks(name, model, attachment)
        attachment.should_run_callbacks = false
        callbacks[name].each do |callback|
          case callback
          when Symbol then model.send(callback)
          when Proc then model.instance_exec(attachment, &callback)
          end
        end
        attachment.should_run_callbacks = true
      end

    end
  end
end
