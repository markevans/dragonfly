module Dragonfly
  module ActiveModelExtensions
    module InstanceMethods
      
      def dragonfly_attachments
        @dragonfly_attachments ||= self.class.dragonfly_attachment_classes.inject({}) do |hash, klass|
          hash[klass.attribute] = klass.new(self)
          hash
        end
      end

      private
      
      def save_dragonfly_attachments
        dragonfly_attachments.each do |attribute, attachment|
          attachment.save!
        end
      end
      
      def destroy_dragonfly_attachments
        dragonfly_attachments.each do |attribute, attachment|
          attachment.destroy!
        end
      end
      
    end
  end
end