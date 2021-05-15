module Dragonfly
  module ParamValidators
    class InvalidParameter < RuntimeError; end

    module_function

    def validate!(parameter, regexp = nil, &validator)
      return if parameter.nil?
      valid = regexp ? !!regexp.match(parameter) : validator.(parameter)
      raise InvalidParameter unless valid
    end

    def validate_all!(parameters, regexp = nil, &validator)
      parameters.each { |p| validate!(p, regexp, &validator) }
    end
  end
end
