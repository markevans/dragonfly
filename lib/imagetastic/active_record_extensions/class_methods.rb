module Imagetastic
  module ActiveRecordExtensions
    module ClassMethods

      def register_imagetastic_app(name, app)
        metaclass.class_eval do
    
          # Defines e.g. 'image_accessor' for any activerecord class body
          define_method "#{name}_accessor" do |attribute|
      
            after_save :save_attached_files unless after_save_callback_chain.find(:save_attached_files)
            before_destroy :destroy_attached_files unless before_destroy_callback_chain.find(:destroy_attached_files)
      
            # Register the new attribute
            registered_imagetastic_apps[attribute] = app
            
            # Define the setter for the attribute
            define_method "#{attribute}=" do |value|
              attachment_for(attribute).assign(value)
            end
      
            # Define the getter for the attribute
            define_method attribute do
              attachment_for(attribute).to_value
            end
      
          end
    
        end
        app
      end

      def registered_imagetastic_apps
        @registered_imagetastic_apps ||= {}
      end

    end
  end
end
