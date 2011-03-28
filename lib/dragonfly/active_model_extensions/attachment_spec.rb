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
            spec.after_assign_callbacks << block
          else
            spec.after_assign_callbacks.push(*callbacks)
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
      
      def after_assign_callbacks
        @after_assign_callbacks ||= []
      end
      
      def run_after_assign_callbacks(attachment, model)
        attachment.run_callbacks = false
        after_assign_callbacks.each do |callback|
          case callback
          when Symbol then model.send(callback)
          when Proc then model.instance_exec(attachment, &callback)
          end
        end
        attachment.run_callbacks = true
      end

    end
  end
end
