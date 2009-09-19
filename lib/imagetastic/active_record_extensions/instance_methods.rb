module Imagetastic
  module ActiveRecordExtensions
    module InstanceMethods
      
      def attachment_for(attribute)
        touched_attachments[attribute] ||= Attachment.new(app_for(attribute), self, attribute)
      end
      
      private
      
      def touched_attachments
        @touched_attachments ||= {}
      end
      
      def attachments
        if @attachments
          @attachments
        else
          @attachments = {}
          self.class.registered_imagetastic_apps.each do |attribute, app|
            @attachments[attribute] = touched_attachments[attribute] || Attachment.new(app, self, attribute)
          end
          @attachments
        end
      end
      
      def app_for(attribute)
        self.class.registered_imagetastic_apps[attribute]
      end
      
      def save_attached_files
        touched_attachments.each do |attribute, attachment|
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