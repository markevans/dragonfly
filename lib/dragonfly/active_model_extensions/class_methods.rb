module Dragonfly
  module ActiveModelExtensions
    module ClassMethods

      include Validations

      def register_dragonfly_app(macro_name, app)
        (class << self; self; end).class_eval do
    
          # Defines e.g. 'image_accessor' for any activerecord class body
          define_method macro_name do |attribute|

            # Prior to activerecord 3, adding before callbacks more than once does add it more than once
            before_save :save_dragonfly_attachments unless respond_to?(:before_save_callback_chain) && before_save_callback_chain.find(:save_dragonfly_attachments)
            before_destroy :destroy_dragonfly_attachments unless respond_to?(:before_destroy_callback_chain) && before_destroy_callback_chain.find(:destroy_dragonfly_attachments)
      
            # Register the new attribute
            dragonfly_attachment_specs << AttachmentSpec.new(attribute, app)
            
            # Define the setter for the attribute
            define_method "#{attribute}=" do |value|
              dragonfly_attachments[attribute].assign(value)
            end
      
            # Define the getter for the attribute
            define_method attribute do
              dragonfly_attachments[attribute].to_value
            end
      
            # Define the URL setter
            define_method "#{attribute}_url=" do |url|
              unless url.blank?
                dragonfly_attachments[attribute].assign(app.fetch_url(url))
              end
            end
      
            # Define the URL getter
            define_method "#{attribute}_url" do
              nil
            end

            # Define the remove setter
            define_method "remove_#{attribute}=" do |value|
              unless [0, "0", false, "false", "", nil].include?(value)
                dragonfly_attachments[attribute].assign(nil)
              end
            end

            # Define the remove getter
            define_method "remove_#{attribute}" do
              false
            end
      
          end
    
        end
        app
      end
      
      def dragonfly_attachment_specs
        @dragonfly_attachment_specs ||= begin
          parent_class = ancestors.select{|a| a.is_a?(Class) }[1]
          parent_class.respond_to?(:dragonfly_attachment_specs) ? parent_class.dragonfly_attachment_specs.dup : []
        end
      end
      
    end
  end
end
