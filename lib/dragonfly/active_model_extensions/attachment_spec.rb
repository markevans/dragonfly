module Dragonfly
  module ActiveModelExtensions
    class AttachmentSpec
      
      def initialize(attribute, app)
        @attribute = attribute
        @app = app
      end
      
      attr_reader :attribute, :app
      
    end
  end
end
