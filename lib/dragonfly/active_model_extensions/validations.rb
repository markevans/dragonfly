module Dragonfly
  module ActiveModelExtensions
    module Validations

      class PropertyValidator < ActiveModel::EachValidator
        
        def validate_each(model, attribute, attachment)
          if attachment
            property = attachment.send(property_name)
            model.errors.add(attribute, message(property, model)) unless matches?(property)
          end
        end
        
        private
        
        def matches?(property)
          if case_insensitive?
            prop = property.to_s.downcase
            allowed_values.any?{|v| v.to_s.downcase == prop }
          else
            allowed_values.include?(property)
          end
        end
        
        def message(property, model)
          message = options[:message] ||
            "#{property_name.to_s.humanize.downcase} is incorrect. " +
            "It needs to be #{expected_values_string}" +
            (property ? ", but was '#{property}'" : "")
          message.respond_to?(:call) ? message.call(property, model) : message
        end
        
        def check_validity!
          raise ArgumentError, "you must provide either :in => [<value1>, <value2>..] or :as => <value>" unless options[:in] || options[:as]
        end
        
        def property_name
          options[:property_name]
        end
        
        def case_insensitive?
          options[:case_sensitive] == false
        end
        
        def allowed_values
          @allowed_values ||= options[:in] || [options[:as]]
        end
        
        def expected_values_string
          if allowed_values.is_a?(Range)
            "between #{allowed_values.first} and #{allowed_values.last}"
          else
            allowed_values.length > 1 ? "one of '#{allowed_values.join('\', \'')}'" : "'#{allowed_values.first.to_s}'"
          end
        end
        
      end

      private

      def validates_property(property_name, options)
        raise ArgumentError, "you need to provide the attribute which has the property, using :of => <attribute_name>" unless options[:of]
        validates_with PropertyValidator, options.merge(:attributes => [*options[:of]], :property_name => property_name)
      end

    end
  end
end