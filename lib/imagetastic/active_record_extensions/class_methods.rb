module Imagetastic
  module ActiveRecordExtensions
    module ClassMethods

      def register_imagetastic_app(name, app)
        metaclass.class_eval do
    
          # Defines e.g. 'image_accessor' for any activerecord class body
          define_method "#{name}_accessor" do |attribute|
      
            before_save :save_attached_files unless before_save_callback_chain.find(:save_attached_files)
            before_destroy :destroy_attached_files unless before_destroy_callback_chain.find(:destroy_attached_files)
      
            # Register the new attribute
            imagetastic_apps_for_attributes[attribute] = app
            
            # Define the setter for the attribute
            define_method "#{attribute}=" do |value|
              attachments[attribute].assign(value)
            end
      
            # Define the getter for the attribute
            define_method attribute do
              attachments[attribute].to_value
            end
      
          end
    
        end
        app
      end
      
      def imagetastic_apps_for_attributes
        @imagetastic_apps_for_attributes ||= {}
      end

    end
  end
end
