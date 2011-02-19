module Dragonfly
  module ActiveModelExtensions
    class AttachmentSpec
      
      def initialize(attribute, app)
        @attribute = attribute
        @app = app
      end
      
      attr_reader :attribute, :app
      
      def new_attachment(model)
        app.attachment_class.new(self, model)
      end
      
    end
  end
end
