module Dragonfly
  module Model
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

          def default(path)
            spec.default_path = path.to_s
          end

          def storage_options(opts=nil, &block)
            spec.storage_options_specs << (opts || block)
          end

          def add_callbacks(name, *callbacks, &block)
            if block_given?
              spec.callbacks[name] << block
            else
              spec.callbacks[name].push(*callbacks)
            end
          end

          def method_missing(meth, *args, &block)
            if key = meth.to_s[/^storage_(.*)$/, 1]
              raise NoMethodError, "#{meth} is deprecated - use storage_options{|a| {#{key}: ...} } instead"
            else
              super
            end
          end

        end

        def init(model_class, attribute, app, config_block)
          @model_class, @attribute, @app, @config_block = model_class, attribute, app, config_block
          include app.job_methods
          ConfigProxy.new(self, config_block) if config_block
          self
        end

        attr_reader :model_class, :attribute, :app, :config_block, :default_path

        def default_path=(path)
          @default_path = path
          app.fetch_file_whitelist.push(path)
        end

        def default_job
          app.fetch_file(default_path) if default_path
        end

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
          app.analyser_methods + [:size, :name]
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
        def storage_options_specs
          @storage_options_specs ||= []
        end

        def evaluate_storage_options(model, attachment)
          storage_options_specs.inject({}) do |opts, spec|
            options = case spec
            when Proc then model.instance_exec(attachment, &spec)
            when Symbol
              meth = model.method(spec)
              (1 === meth.arity) ? meth.call(attachment) : meth.call
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
