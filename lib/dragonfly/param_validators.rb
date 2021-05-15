module Dragonfly
  module ParamValidators
    class InvalidParameter < RuntimeError; end

    module_function

    def validate!(parameter, regexp = nil, &validator)
      return if parameter.nil?
      valid = regexp ? !!regexp.match(parameter) : validator.(parameter)
      raise InvalidParameter unless valid
    end
  end
end
