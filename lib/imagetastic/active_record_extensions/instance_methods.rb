module Imagetastic
  module ActiveRecordExtensions
    module InstanceMethods
      
      def attachments
        @attachments ||= self.class.imagetastic_apps_for_attributes.inject({}) do |hash, (attribute, app)|
          hash[attribute] = Attachment.new(app, self, attribute)
          hash
        end
      end

      private
      
      def save_attached_files
        attachments.each do |attribute, attachment|
          attachment.save!
        end
      end
      
      def destroy_attached_files
        attachments.each do |attribute, attachment|
          attachment.destroy!
        end
      end
      
    end
  end
end