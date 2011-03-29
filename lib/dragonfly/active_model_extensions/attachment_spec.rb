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
          if block_given?
            spec.callbacks[:after_assign] << block
          else
            spec.callbacks[:after_assign].push(*callbacks)
          end
        end
        
        def after_unassign(*callbacks, &block)
          if block_given?
            spec.callbacks[:after_unassign] << block
          else
            spec.callbacks[:after_unassign].push(*callbacks)
          end
        end
        
        def copy_to(accessor, &block)
          if block_given?
            after_assign{|a| self.send("#{accessor}=", instance_exec(a, &block)) }
            after_unassign{|a| self.send("#{accessor}=", nil) }
          else
            after_assign{|a| self.send("#{accessor}=", a) }
            after_unassign{|a| self.send("#{accessor}=", nil) }
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
        callbacks[name].each do |c|
          evaluate_callback(c, model, attachment)
        end
        attachment.should_run_callbacks = true
      end

      private
      
      def evaluate_callback(callback, model, attachment)
        case callback
        when Symbol then model.send(callback)
        when Proc then model.instance_exec(attachment, &callback)
        end
      end

    end
  end
end
