require 'dragonfly'
require 'dragonfly/serializer'
require 'dragonfly/utils'
require 'dragonfly/model/attachment'

module Dragonfly
  module Model
    module ClassMethods

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

      private

      def dragonfly_accessor(attribute, opts={}, &config_block)
        app = case opts[:app]
        when Symbol, nil then Dragonfly.app(opts[:app])
        else opts[:app]
        end

        # Add callbacks
        before_save :save_dragonfly_attachments if respond_to?(:before_save)
        before_destroy :destroy_dragonfly_attachments if respond_to?(:before_destroy)

        # Register the new attribute
        dragonfly_attachment_classes << new_dragonfly_attachment_class(attribute, app, config_block)

        # Define an anonymous module for all of the attribute-specific instance
        # methods.
        instance_methods = Module.new do
          # Define the setter for the attribute
          define_method "#{attribute}=" do |value|
            dragonfly_attachments[attribute].assign(value)
          end

          # Define the getter for the attribute
          define_method attribute do
            dragonfly_attachments[attribute].to_value
          end

          # Define the xxx_stored? method
          define_method "#{attribute}_stored?" do
            dragonfly_attachments[attribute].stored?
          end

          # Define the xxx_changed? method
          define_method "#{attribute}_changed?" do
            dragonfly_attachments[attribute].changed?
          end

          # Define the URL setter
          define_method "#{attribute}_url=" do |url|
            unless Utils.blank?(url)
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
            unless Utils.blank?(string)
              begin
                dragonfly_attachments[attribute].retained_attrs = Serializer.json_b64_decode(string)
              rescue Serializer::BadString => e
                Dragonfly.warn("couldn't update attachment with serialized retained_#{attribute} string #{string.inspect}")
              end
            end
            dragonfly_attachments[attribute].should_retain = true
            dragonfly_attachments[attribute].retain!
            string
          end

          # Define the retained getter
          define_method "retained_#{attribute}" do
            attrs = dragonfly_attachments[attribute].retained_attrs
            Serializer.json_b64_encode(attrs) if attrs
          end
        end

        include instance_methods
      end

      def new_dragonfly_attachment_class(attribute, app, config_block)
        Class.new(Attachment).init(self, attribute, app, config_block)
      end

    end
  end
end
