require 'forwardable'

module Dragonfly
  module ActiveModelExtensions
    
    class PendingUID; def to_s; 'PENDING'; end; end
    
    class Attachment
      
      extend Forwardable
      def_delegators :job,
        :data, :to_file, :file, :tempfile, :path,
        :process, :encode, :analyse
      
      def initialize(app, parent_model, attribute_name)
        @app, @parent_model, @attribute_name = app, parent_model, attribute_name
        self.extend app.analyser.analysis_methods
        self.extend app.job_definitions
        self.job = app.fetch(uid) if been_persisted?
      end
      
      def assign(value)
        if value.nil?
          self.job = nil
          self.uid = nil
          reset_magic_attributes
        else
          self.job = Job.new(app, TempObject.new(value))
          self.uid = PendingUID.new
          set_magic_attributes
        end
        value
      end

      def destroy!
        app.datastore.destroy(previous_uid) if previous_uid
      rescue DataStorage::DataNotFound => e
        app.log.warn("*** WARNING ***: tried to destroy data with uid #{previous_uid}, but got error: #{e}")
      end
      
      def save!
        destroy! if uid_changed?
        self.uid = app.datastore.store(job.result) if has_data_to_store?
      end
      
      def to_value
        self if been_assigned?
      end
      
      def url
        unless uid.nil? || uid.is_a?(PendingUID)
          app.url_for(job)
        end
      end
      
      def analyse(meth, *args)
        has_magic_attribute_for?(meth) ? magic_attribute_for(meth) : job.send(meth)
      end
      
      [:size, :ext, :name].each do |meth|
        define_method meth do
          analyse(meth)
        end
      end
      
      private
      
      def been_assigned?
        uid
      end
      
      def been_persisted?
        uid && !uid.is_a?(PendingUID)
      end
      
      def has_data_to_store?
        uid.is_a?(PendingUID)
      end
      
      def uid_changed?
        parent_model.send("#{attribute_name}_uid_changed?")
      end
      
      def uid=(uid)
        parent_model.send("#{attribute_name}_uid=", uid)
      end
      
      def uid
        parent_model.send("#{attribute_name}_uid")
      end
      
      def previous_uid
        parent_model.send("#{attribute_name}_uid_was")
      end
      
      attr_reader :app, :parent_model, :attribute_name
      
      attr_accessor :job
      
      def allowed_magic_attributes
        app.analyser.analysis_method_names + [:size, :ext, :name]
      end
      
      def magic_attributes
        parent_model.class.column_names.select { |name|
          name =~ /^#{attribute_name}_(.+)$/ && allowed_magic_attributes.include?($1.to_sym)
        }
      end
      
      def set_magic_attributes
        magic_attributes.each do |attribute|
          method = attribute.sub("#{attribute_name}_", '')
          parent_model.send("#{attribute}=", job.send(method))
        end
      end
      
      def reset_magic_attributes
        magic_attributes.each{|attribute| parent_model.send("#{attribute}=", nil) }
      end
      
      def has_magic_attribute_for?(property)
        magic_attributes.include?("#{attribute_name}_#{property}")
      end
      
      def magic_attribute_for(property)
        parent_model.send("#{attribute_name}_#{property}")
      end
      
    end
  end
end