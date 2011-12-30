module Dragonfly
  module ActiveModelExtensions
    class Attachment
      class << self
    
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
      
          def storage_opts(opts=nil, &block)
            spec.storage_opts_specs << (opts || block)
          end

          def storage_opt(key, value, &block)
            if value.is_a? Symbol
              storage_opts{|a| {key => send(value)} }
            elsif block_given?
              storage_opts{|a| {key => instance_exec(a, &block)} }
            else
              storage_opts{|a| {key => value} }
            end
          end
      
          def add_callbacks(name, *callbacks, &block)
            if block_given?
              spec.callbacks[name] << block
            else
              spec.callbacks[name].push(*callbacks)
            end
          end
      
          def method_missing(meth, *args, &block)
            if meth.to_s =~ /^storage_(.*)$/
              storage_opt($1.to_sym, args.first, &block)
            else
              super
            end
          end
      
        end
    
        def init(model_class, attribute, app, config_block)
          @model_class, @attribute, @app, @config_block = model_class, attribute, app, config_block
          include app.analyser.analysis_methods
          include app.job_definitions
          define_method :format do
            job.format
          end
          define_method :mime_type do
            job.mime_type
          end
          ConfigProxy.new(self, config_block) if config_block
          self
        end

        attr_reader :model_class, :attribute, :app, :config_block

        # Callbacks
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

        # Magic attributes
        def allowed_magic_attributes
          app.analyser.analysis_method_names + [:size, :name]
        end

        def magic_attributes
          @magic_attributes ||= begin
            prefix = attribute.to_s + '_'
            model_class.public_instance_methods.inject([]) do |attrs, name|
              _, __, suffix  = name.to_s.partition(prefix)
              if !suffix.empty? && allowed_magic_attributes.include?(suffix.to_sym)
                attrs << suffix.to_sym
              end
              attrs
            end
          end
        end

        def ensure_uses_cached_magic_attributes
          return if @uses_cached_magic_attributes
          magic_attributes.each do |attr|
            define_method attr do
              magic_attribute_for(attr)
            end
          end
          @uses_cached_magic_attributes = true
        end

        # Storage options
        def storage_opts_specs
          @storage_opts_specs ||= []
        end
    
        def evaluate_storage_opts(model, attachment)
          storage_opts_specs.inject({}) do |opts, spec|
            options = case spec
            when Proc then model.instance_exec(attachment, &spec)
            when Symbol then model.send(spec)
            else spec
            end
            opts.merge!(options)
            opts
          end
        end

      end
    end
  end
end
