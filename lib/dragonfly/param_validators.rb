module Dragonfly
  module ParamValidators
    class InvalidParameter < RuntimeError; end

    module_function

    def validate!(parameter, &validator)
      raise InvalidParameter unless parameter.nil? || validator.(parameter)
    end
  end
end
