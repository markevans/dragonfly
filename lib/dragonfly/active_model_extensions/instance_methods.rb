module Dragonfly
  module ActiveModelExtensions
    module InstanceMethods
      
      def attachments
        @attachments ||= self.class.dragonfly_apps_for_attributes.inject({}) do |hash, (attribute, app)|
          hash[attribute] = Attachment.new(app, self, attribute)
          hash
        end
      end

      private
      
      def save_attachments
        attachments.each do |attribute, attachment|
          attachment.save!
        end
      end
      
      def destroy_attachments
        attachments.each do |attribute, attachment|
          attachment.destroy!
        end
      end
      
    end
  end
end