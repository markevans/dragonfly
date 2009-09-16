module Imagetastic
  module ActiveRecordExtensions
    class Attachment
      
      def initialize(app)
        @app = app
      end
      
      def assign(value)
        self.temp_object = Imagetastic::TempObject.new(value)
        value
      end

      def destroy
        todo
      end
      
      def save
        self.uid = app.datastore.store(temp_object)
      end
      
      def to_value
        todo
      end
      
      private
      
      attr_reader :app
      
      attr_accessor :uid, :temp_object
      
    end
  end
end