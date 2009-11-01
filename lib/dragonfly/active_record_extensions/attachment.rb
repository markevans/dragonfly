module Dragonfly
  module ActiveRecordExtensions
    
    class PendingUID; def to_s; 'PENDING'; end; end
    
    class Attachment
      
      def initialize(app, parent_model, attribute_name)
        @app, @parent_model, @attribute_name = app, parent_model, attribute_name
      end
      
      def assign(value)
        if value.nil?
          self.model_uid = nil
        else
          self.temp_object = Dragonfly::TempObject.new(value)
          self.model_uid = PendingUID.new
        end
        value
      end

      def destroy!
        app.datastore.destroy(previous_uid) if previous_uid
      end
      
      def save!
        if changed?
          app.datastore.destroy(previous_uid) if previous_uid
          self.model_uid = app.datastore.store(temp_object)
        end
      end
      
      def to_value
        self if been_assigned?
      end
      
      def url(*args)
        unless model_uid.nil? || model_uid.is_a?(PendingUID)
          app.url_for(model_uid, *args)
        end
      end
      
      private
      
      def been_assigned?
        model_uid
      end
      
      def changed?
        parent_model.send("#{attribute_name}_uid_changed?")
      end
      
      def model_uid=(uid)
        parent_model.send("#{attribute_name}_uid=", uid)
      end
      
      def model_uid
        parent_model.send("#{attribute_name}_uid")
      end
      
      def previous_uid
        parent_model.send("#{attribute_name}_uid_was")
      end
      
      attr_reader :app, :parent_model, :attribute_name
      
      attr_accessor :temp_object
      
    end
  end
end