module Imagetastic
  module ActiveRecordExtensions
    
    class PendingUID; def to_s; 'PENDING'; end; end
    
    class Attachment
      
      def initialize(app, parent_model, attribute_name)
        @app, @parent_model, @attribute_name = app, parent_model, attribute_name
      end
      
      def assign(value)
        self.temp_object = Imagetastic::TempObject.new(value)
        set_uid(PendingUID.new)
        value
      end

      def destroy!
        todo
      end
      
      def save!
        if changed?
          app.datastore.destroy(previous_uid) if previous_uid
          set_uid(app.datastore.store(temp_object))
        end
      end
      
      def to_value
        todo
      end
      
      private
      
      def changed?
        parent_model.send("#{attribute_name}_uid_changed?")
      end
      
      def set_uid(uid)
        parent_model.send("#{attribute_name}_uid=", uid)
      end
      
      def previous_uid
        parent_model.send("#{attribute_name}_uid_was")
      end
      
      attr_reader :app, :parent_model, :attribute_name
      
      attr_accessor :temp_object
      
    end
  end
end