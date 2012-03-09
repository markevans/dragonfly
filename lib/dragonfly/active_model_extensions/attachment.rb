require 'forwardable'
require 'dragonfly/active_model_extensions/attachment_class_methods'

module Dragonfly
  module ActiveModelExtensions

    class Attachment

      # Exceptions
      class BadAssignmentKey < RuntimeError; end

      extend Forwardable
      def_delegators :job,
        :data, :to_file, :file, :tempfile, :path,
        :process, :encode, :analyse,
        :meta, :meta=,
        :name, :size,
        :url

      include HasFilename

      alias_method :length, :size
      
      def initialize(model)
        @model = model
        self.uid = model_uid
        set_job_from_uid if uid
        @should_run_callbacks = true
        self.class.ensure_uses_cached_magic_attributes
      end

      def app
        self.class.app
      end
      
      def attribute
        self.class.attribute
      end

      def assign(value)
        self.changed = true
        destroy_retained! if retained?
        set_uid_and_model_uid(nil)
        if value.nil?
          self.job = nil
          reset_magic_attributes
          self.class.run_callbacks(:after_unassign, model, self) if should_run_callbacks?
        else
          self.job = case value
          when Job then value.dup
          when self.class then value.job.dup
          else app.new_job(value)
          end
          set_magic_attributes
          job.url_attrs = all_extra_attributes
          self.class.run_callbacks(:after_assign, model, self) if should_run_callbacks?
          retain! if should_retain?
        end
        model_uid_will_change!
        value
      end

      def changed?
        !!@changed
      end

      def destroy!
        destroy_previous!
        destroy_content(uid) if uid
      end

      def save!
        sync_with_model
        store_job! if job && !uid
        destroy_previous!
        self.changed = false
        self.retained = false
      end

      def to_value
        self if job
      end

      def name=(name)
        set_magic_attribute(:name, name) if has_magic_attribute_for?(:name)
        job.name = name
      end

      def process!(*args)
        assign(process(*args))
        self
      end

      def encode!(*args)
        assign(encode(*args))
        self
      end
      
      def remote_url(opts={})
        app.remote_url_for(uid, opts) if uid
      end
      
      def apply
        job.apply
        self
      end

      attr_writer :should_run_callbacks
      
      def should_run_callbacks?
        !!@should_run_callbacks
      end

      # Retaining for avoiding uploading more than once

      def retain!
        if changed? && job
          store_job!
          self.retained = true
        end
      end

      attr_writer :should_retain
      
      def should_retain?
        !!@should_retain
      end
      
      def retained?
        !!@retained
      end
      
      def destroy_retained!
        destroy_content(retained_attrs[:uid])
      end
      
      def retained_attrs
        attribute_keys.inject({}) do |hash, key|
          hash[key] = send(key)
          hash
        end if retained?
      end
      
      def retained_attrs=(attrs)
        if changed? # if already set, ignore and destroy this retained content
          destroy_content(attrs[:uid])
        else
          attrs.each do |key, value|
            unless attribute_keys.include?(key)
              raise BadAssignmentKey, "trying to call #{attribute}_#{key} = #{value.inspect} via retained_#{attribute} but this is not allowed!"
            end
            model.send("#{attribute}_#{key}=", value)
          end
          sync_with_model
          set_job_from_uid
          self.retained = true
        end
      end
      
      def inspect
        "<Dragonfly Attachment uid=#{uid.inspect}, app=#{app.name.inspect}>"
      end

      protected

      attr_reader :job

      private

      attr_writer :changed, :retained

      def attribute_keys
        [:uid] + magic_attributes
      end

      def store_job!
        meta.merge!(all_extra_attributes)
        opts = self.class.evaluate_storage_opts(model, self)
        set_uid_and_model_uid job.store(opts)
        self.job = job.to_fetched_job(uid)
      end

      def destroy_content(uid)
        app.datastore.destroy(uid)
      rescue DataStorage::DataNotFound, DataStorage::DestroyError => e
        app.log.warn("*** WARNING ***: tried to destroy data with uid #{uid}, but got error: #{e}")
      end

      def destroy_previous!
        if previous_uid
          destroy_content(previous_uid)
          self.previous_uid = nil
        end
      end

      def sync_with_model
        # If the model uid has been set manually
        if uid != model_uid
          self.uid = model_uid
        end
      end

      def set_uid_and_model_uid(uid)
        self.uid = uid
        self.model_uid = uid
      end

      def model_uid=(uid)
        model.send("#{attribute}_uid=", uid)
      end

      def model_uid
        model.send("#{attribute}_uid")
      end

      def model_uid_will_change!
        meth = "#{attribute}_uid_will_change!"
        model.send(meth) if model.respond_to?(meth)
      end
      
      attr_reader :model, :uid
      attr_writer :job
      attr_accessor :previous_uid

      def uid=(uid)
        self.previous_uid = @uid if @uid
        @uid = uid
      end

      def magic_attributes
        self.class.magic_attributes
      end

      def set_magic_attribute(property, value)
        model.send("#{attribute}_#{property}=", value)
      end

      def set_magic_attributes
        magic_attributes.each{|property| set_magic_attribute(property, job.send(property)) }
      end

      def reset_magic_attributes
        magic_attributes.each{|property| set_magic_attribute(property, nil) }
      end

      def has_magic_attribute_for?(property)
        magic_attributes.include?(property.to_sym)
      end

      def magic_attribute_for(property)
        model.send("#{attribute}_#{property}")
      end

      def magic_attributes_hash
        magic_attributes.inject({}) do |attrs, property|
          attrs[property] = model.send("#{attribute}_#{property}")
          attrs
        end
      end

      def extra_attributes
        @extra_attributes ||= {
          :model_class => model.class.name,
          :model_attachment => attribute
        }
      end
      
      def all_extra_attributes
        magic_attributes_hash.merge(extra_attributes)
      end
      
      def set_job_from_uid
        self.job = app.fetch(uid)
        job.url_attrs = all_extra_attributes
      end

    end
  end
end