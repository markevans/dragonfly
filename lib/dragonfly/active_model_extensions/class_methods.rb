module Dragonfly
  module ActiveModelExtensions
    module ClassMethods

      include Validations

      def register_dragonfly_app(macro_name, app)
        (class << self; self; end).class_eval do
    
          # Defines e.g. 'image_accessor' for any activemodel class body
          define_method macro_name do |attribute, &config_block|

            # Add callbacks
            before_save :save_dragonfly_attachments
            before_destroy :destroy_dragonfly_attachments
      
            # Register the new attribute
            dragonfly_attachment_classes << new_dragonfly_attachment_class(attribute, app, config_block)
            
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
                instance_variable_set("@remove_#{attribute}", true)
              end
            end

            # Define the remove getter
            attr_reader "remove_#{attribute}"

            # Define the retained setter
            define_method "retained_#{attribute}=" do |string|
              unless string.blank?
                begin
                  dragonfly_attachments[attribute].retained_attrs = Serializer.marshal_decode(string)
                rescue Serializer::BadString => e
                  app.log.warn("*** WARNING ***: couldn't update attachment with serialized retained_#{attribute} string #{string.inspect}")              
                end
              end
              dragonfly_attachments[attribute].should_retain = true
              dragonfly_attachments[attribute].retain!
              string
            end
            
            # Define the retained getter
            define_method "retained_#{attribute}" do
              attrs = dragonfly_attachments[attribute].retained_attrs
              Serializer.marshal_encode(attrs) if attrs
            end
            
          end
    
        end
        app
      end
      
      def dragonfly_attachment_classes
        @dragonfly_attachment_classes ||= begin
          parent_class = ancestors.select{|a| a.is_a?(Class) }[1]
          if parent_class.respond_to?(:dragonfly_attachment_classes)
            parent_class.dragonfly_attachment_classes.map do |klass|
              new_dragonfly_attachment_class(klass.attribute, klass.app, klass.config_block)
            end
          else
            []
          end
        end
      end
      
      def new_dragonfly_attachment_class(attribute, app, config_block)
        Class.new(Attachment).init(self, attribute, app, config_block)
      end
      
    end
  end
end
