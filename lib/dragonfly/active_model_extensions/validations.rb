module Dragonfly
  module ActiveModelExtensions
    module Validations

      private

      def validates_property(property_name, opts)
        attrs = opts[:of] or raise ArgumentError, "you need to provide the attribute which has the property, using :of => <attribute_name>"
        attrs = [attrs].flatten #(make sure it's an array)

        raise ArgumentError, "you must provide either :in => [<value1>, <value2>..] or :as => <value>" unless opts[:in] || opts[:as]
        allowed_values = opts[:in] || [opts[:as]]

        args = attrs + [opts]
        validates_each(*args) do |model, attr, attachment|
          if attachment
            property = attachment.send(property_name)
            unless allowed_values.include?(property)
              message = opts[:message] ||
                "#{property_name.to_s.humanize.downcase} is incorrect. "+
                "It needs to be #{Validations.expected_values_string(allowed_values)}"+
                (property ? ", but was '#{property}'" : "")
              message = message.call(property, model) if message.respond_to?(:call)
              model.errors.add(attr, message)
            end
          end
        end

      end

      def self.expected_values_string(allowed_values)
        if allowed_values.is_a?(Range)
          "between #{allowed_values.first} and #{allowed_values.last}"
        else
          allowed_values.length > 1 ? "one of '#{allowed_values.join('\', \'')}'" : "'#{allowed_values.first.to_s}'"
        end
      end

    end
  end
end