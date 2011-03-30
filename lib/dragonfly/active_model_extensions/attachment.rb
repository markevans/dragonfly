require 'forwardable'

module Dragonfly
  module ActiveModelExtensions

    class Attachment

      extend Forwardable
      def_delegators :job,
        :data, :to_file, :file, :tempfile, :path,
        :process, :encode, :analyse,
        :meta, :meta=,
        :name, :ext,
        :url

      def_delegators :spec,
        :app, :attribute

      def initialize(spec, parent_model)
        @spec, @parent_model = spec, parent_model
        self.uid = parent_uid
        update_from_uid if uid
        @should_run_callbacks = true
      end

      def assign(value)
        if value.nil?
          self.job = nil
          reset_magic_attributes
          spec.run_callbacks(:after_unassign, parent_model, self) if should_run_callbacks?
        else
          self.job = case value
          when Job then value.dup
          when self.class then value.job.dup
          else app.new_job(value)
          end
          set_magic_attributes
          update_meta
          spec.run_callbacks(:after_assign, parent_model, self) if should_run_callbacks?
        end
        set_uid_and_parent_uid(nil)
        self.changed = true
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
        sync_with_parent
        store_job! if job && !uid
        destroy_previous!
        self.changed = false
        self.retained = false
      end

      def to_value
        self if job
      end

      def analyse(meth, *args)
        has_magic_attribute_for?(meth) ? magic_attribute_for(meth) : job.send(meth)
      end

      def size
        analyse(:size)
      end

      def name=(name)
        job.name = name
        set_magic_attribute(:name, name) if has_magic_attribute_for?(:name)
        name
      end

      def process!(*args)
        assign(process(*args))
        self
      end

      def encode!(*args)
        assign(encode(*args))
        self
      end
      
      def remote_url(*args)
        app.remote_url_for(uid, *args) if uid
      end
      
      def apply
        job.apply
        self
      end

      attr_writer :should_run_callbacks
      
      def should_run_callbacks?
        @should_run_callbacks
      end

      # Retaining for avoiding uploading more than once

      def retain!
        if changed?
          store_job!
          self.retained = true
        end
      end

      def retained?
        !!@retained
      end

      def serialized_attributes
        Serializer.marshal_encode(attributes)
      end
      
      def from_serialized(string)
        attrs = Serializer.marshal_decode(string)
        attrs.each do |key, value|
          parent_model.send("#{attribute}_#{key}=", value)
        end
        sync_with_parent
        update_from_uid
      end

      protected

      attr_reader :job

      private

      attr_writer :changed, :retained

      def attributes
        ([:uid] + magic_attributes).inject({}) do |hash, key|
          hash[key] = send(key)
          hash
        end
      end

      def store_job!
        opts = spec.evaluate_storage_opts(parent_model, self)
        set_uid_and_parent_uid job.store(opts)
        self.job = job.to_fetched_job(uid)
      end

      def destroy_content(uid)
        app.datastore.destroy(uid)
      rescue DataStorage::DataNotFound => e
        app.log.warn("*** WARNING ***: tried to destroy data with uid #{uid}, but got error: #{e}")
      end

      def destroy_previous!
        if previous_uid
          destroy_content(previous_uid)
          self.previous_uid = nil
        end
      end

      def sync_with_parent
        # If the parent uid has been set manually
        if uid != parent_uid
          self.uid = parent_uid
        end
      end

      def set_uid_and_parent_uid(uid)
        self.uid = uid
        self.parent_uid = uid
      end

      def parent_uid=(uid)
        parent_model.send("#{attribute}_uid=", uid)
      end

      def parent_uid
        parent_model.send("#{attribute}_uid")
      end

      attr_reader :spec, :parent_model
      attr_writer :job
      attr_accessor :previous_uid
      attr_reader :uid

      def uid=(uid)
        self.previous_uid = @uid if @uid
        @uid = uid
      end

      def update_meta
        magic_attributes.each{|property| meta[property] = parent_model.send("#{attribute}_#{property}") }
        meta[:model_class] = parent_model.class.name
        meta[:model_attachment] = attribute
      end

      def update_from_uid
        self.job = app.fetch(uid)
        update_meta
      end

      def allowed_magic_attributes
        app.analyser.analysis_method_names + [:size, :name]
      end

      def magic_attributes
        @magic_attributes ||= begin
          prefix = attribute.to_s + '_'
          parent_model.public_methods.inject([]) do |attrs, name|
            _, __, suffix  = name.to_s.partition(prefix)
            if !suffix.empty? && allowed_magic_attributes.include?(suffix.to_sym)
              attrs << suffix.to_sym
            end
            attrs
          end
        end
      end

      def set_magic_attribute(property, value)
        parent_model.send("#{attribute}_#{property}=", value)
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
        parent_model.send("#{attribute}_#{property}")
      end

    end
  end
end