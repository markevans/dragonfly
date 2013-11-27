require 'forwardable'
require 'dragonfly/has_filename'
require 'dragonfly/job'
require 'dragonfly/model/attachment_class_methods'

module Dragonfly
  module Model
    class Attachment

      # Exceptions
      class BadAssignmentKey < RuntimeError; end

      extend Forwardable
      def_delegators :job,
        :to_file, :file, :tempfile, :path,
        :data, :b64_data, :mime_type,
        :process, :analyse, :shell_eval,
        :meta, :meta=,
        :name, :size,
        :url

      include HasFilename

      alias_method :length, :size

      def initialize(model)
        @model = model
        self.uid = model_uid
        set_job_from_uid if uid?
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
          self.job = app.new_job(value)
          set_magic_attributes
          job.update_url_attributes(magic_attributes_hash)
          meta.merge!(standard_meta_attributes)
          self.class.run_callbacks(:after_assign, model, self) if should_run_callbacks?
          retain! if should_retain?
        end
        model_uid_will_change!
        value
      end

      def changed?
        !!@changed
      end

      def stored?
        uid?
      end

      def destroy!
        destroy_previous!
        destroy_content(uid) if uid?
      end

      def save!
        sync_with_model
        store_job! if job && !uid
        destroy_previous!
        self.changed = false
        self.retained = false
      end

      def to_value
        (self if job) || self.class.default_job
      end

      def name=(name)
        set_magic_attribute(:name, name) if has_magic_attribute_for?(:name)
        job.name = name
      end

      def process!(*args)
        assign(process(*args))
        self
      end

      def remote_url(opts={})
        app.remote_url_for(uid, opts) if uid?
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
        destroy_content(retained_attrs['uid'])
      end

      def retained_attrs
        attribute_keys.inject({}) do |hash, key|
          hash[key] = send(key)
          hash
        end if retained?
      end

      def retained_attrs=(attrs)
        if changed? # if already set, ignore and destroy this retained content
          destroy_content(attrs['uid'])
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

      def add_meta(meta)
        job.add_meta(meta)
        self
      end

      def inspect
        "<Dragonfly Attachment uid=#{uid.inspect}, app=#{app.name.inspect}>"
      end

      attr_reader :job

      private

      attr_writer :changed, :retained

      def attribute_keys
        @attribute_keys ||= ['uid'] + magic_attributes.map{|attribute| attribute.to_s }
      end

      def store_job!
        opts = self.class.evaluate_storage_options(model, self)
        set_uid_and_model_uid job.store(opts)
        self.job = job.to_fetched_job(uid)
      end

      def destroy_content(uid)
        app.datastore.destroy(uid)
      end

      def destroy_previous!
        if previous_uid?
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

      def uid?
        !uid.nil? && !uid.empty?
      end

      def previous_uid?
         !previous_uid.nil? && !previous_uid.empty?
      end

      def magic_attributes
        self.class.magic_attributes
      end

      def set_magic_attribute(property, value)
        model.send("#{attribute}_#{property}=", value)
      end

      def set_magic_attributes
        magic_attributes.each do |property|
          value = begin
            job.send(property)
          rescue RuntimeError => e
            Dragonfly.warn("setting magic attribute for #{property} to nil in #{self.inspect} because got error #{e}")
            nil
          end
          set_magic_attribute(property, value)
        end
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
          attrs[property.to_s] = model.send("#{attribute}_#{property}")
          attrs
        end
      end

      def standard_meta_attributes
        @standard_meta_attributes ||= {
          'model_class' => model.class.name,
          'model_attachment' => attribute.to_s
        }
      end

      def set_job_from_uid
        self.job = app.fetch(uid)
        job.update_url_attributes(magic_attributes_hash)
      end

    end
  end
end

