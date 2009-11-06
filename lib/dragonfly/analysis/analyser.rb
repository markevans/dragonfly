module Dragonfly
  module Analysis
    class Analyser
      
      def initialize
        @analysers = []
      end
      
      include Configurable

      def register(analyser)
        analysers.unshift(analyser)
      end
      configuration_method :register

      def mime_type(temp_object)
        analysers.each do |analyser|
          mime_type = analyser.mime_type(temp_object)
          return mime_type if mime_type
        end
        nil
      end
      
      private
      
      attr_reader :analysers

    end
  end
end