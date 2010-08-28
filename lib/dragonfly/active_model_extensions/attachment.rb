require 'forwardable'

module Dragonfly
  module ActiveModelExtensions

    class Attachment

      extend Forwardable
      def_delegators :job,
        :data, :to_file, :file, :tempfile, :path,
        :process, :encode, :analyse,
        :url

      def initialize(app, parent_model, attribute_name)
        @app, @parent_model, @attribute_name = app, parent_model, attribute_name
        self.extend app.analyser.analysis_methods
        self.extend app.job_definitions
        self.uid = parent_uid
        self.job = app.fetch(uid) if uid
      end

      def assign(value)
        if value.nil?
          self.job = nil
          reset_magic_attributes
        else
          self.job = case value
          when Job then value.dup
          when self.class then value.job.dup
          else app.new_job(value)
          end
          set_magic_attributes
        end
        set_uid_and_parent_uid(nil)
        value
      end

      def destroy!
        destroy_previous!
        destroy_content(uid) if uid
      end

      def save!
        sync_with_parent!
        destroy_previous!
        if job && !uid
          set_uid_and_parent_uid app.store(job.result)
          self.job = job.to_fetched_job(uid)
        end
      end

      def to_value
        self if job
      end

      def analyse(meth, *args)
        has_magic_attribute_for?(meth) ? magic_attribute_for(meth) : job.send(meth)
      end

      [:size, :ext, :name].each do |meth|
        define_method meth do
          analyse(meth)
        end
      end

      def process!(*args)
        assign(process(*args))
        self
      end

      def encode!(*args)
        assign(encode(*args))
        self
      end

      protected

      attr_reader :job

      private

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

      def sync_with_parent!
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
        parent_model.send("#{attribute_name}_uid=", uid)
      end

      def parent_uid
        parent_model.send("#{attribute_name}_uid")
      end

      attr_reader :app, :parent_model, :attribute_name
      attr_writer :job
      attr_accessor :previous_uid
      attr_reader :uid

      def uid=(uid)
        self.previous_uid = @uid if @uid
        @uid = uid
      end

      def allowed_magic_attributes
        app.analyser.analysis_method_names + [:size, :ext, :name]
      end

      def magic_attributes
        parent_model.public_methods.select { |name|
          name.to_s =~ /^#{attribute_name}_(.+)$/ && allowed_magic_attributes.include?($1.to_sym)
        }
      end

      def set_magic_attributes
        magic_attributes.each do |attribute|
          method = attribute.to_s.sub("#{attribute_name}_", '')
          parent_model.send("#{attribute}=", job.send(method))
        end
      end

      def reset_magic_attributes
        magic_attributes.each{|attribute| parent_model.send("#{attribute}=", nil) }
      end

      def has_magic_attribute_for?(property)
        magic_attributes.include?("#{attribute_name}_#{property}".to_method_name)
      end

      def magic_attribute_for(property)
        parent_model.send("#{attribute_name}_#{property}")
      end

    end
  end
end