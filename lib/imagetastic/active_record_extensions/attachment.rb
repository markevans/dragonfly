module Imagetastic
  module ActiveRecordExtensions
    class Attachment
      
      def initialize(app, parent_model)
        @app = app
        @parent_model = parent_model
      end
      
      def assign(value)
        self.temp_object = Imagetastic::TempObject.new(value)
        @dirty = true
        value
      end

      def destroy
        todo
      end
      
      def save
        old_uid = uid
        self.uid = app.datastore.store(temp_object) if dirty?
        app.datastore.destroy(old_uid) if old_uid
        @dirty = false
        true
      end
      
      def to_value
        todo
      end
      
      private
      
      attr_reader :app, :parent_model
      
      attr_accessor :uid, :temp_object
      
      def dirty?
        !!@dirty
      end
      
    end
  end
end