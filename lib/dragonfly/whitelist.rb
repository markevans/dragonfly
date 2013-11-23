require 'forwardable'

module Dragonfly
  class Whitelist
    extend Forwardable
    def_delegators :patterns, :push

    def initialize(patterns=[])
      @patterns = patterns
    end

    attr_reader :patterns

    def include?(string)
      patterns.any?{|pattern| pattern === string }
    end
  end
end

