module Dragonfly
  module ParamValidators
    class InvalidParameter < RuntimeError; end

    module_function

    IS_NUMBER = ->(param) {
      param.is_a?(Numeric) || /\A[\d\.]+\z/ === param
    }

    IS_COLOUR = ->(param) {
      /\A(#\w+|rgba?\([\d\.,]+\)|\w+)\z/ === param
    }

    IS_WORD = ->(param) {
      /\A\w+\z/ === param
    }

    IS_WORDS = ->(param) {
      /\A[\w ]+\z/ === param
    }

    def is_number; IS_NUMBER; end
    def is_colour; IS_COLOUR; end
    def is_word; IS_WORD; end
    def is_words; IS_WORDS; end

    alias is_color is_colour

    def validate!(parameter, &validator)
      return if parameter.nil?
      raise InvalidParameter unless validator.(parameter)
    end

    def validate_all!(parameters, &validator)
      parameters.each { |p| validate!(p, &validator) }
    end

    def validate_all_keys!(obj, keys, &validator)
      parameters = keys.map { |key| obj[key] }
      validate_all!(parameters, &validator)
    end
  end
end
