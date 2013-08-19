module Dragonfly
  class Whitelist
    def initialize(patterns)
      @patterns = patterns
    end

    attr_reader :patterns

    def include?(string)
      patterns.any?{|pattern| pattern === string }
    end
  end
end

