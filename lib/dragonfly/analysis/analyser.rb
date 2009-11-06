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
      
      def analysis_methods
        analysers.map{|a| a.public_methods(false) }.flatten.uniq.reject{|a| a == 'mime_type'}
      end
      
      def has_analysis_method?(method)
        analysis_methods.include?(method.to_s)
      end
      
      private
      
      attr_reader :analysers

      def method_missing(meth, *args)
        analysers.each do |analyser|
          return analyser.send(meth, *args) if analyser.respond_to?(meth)
        end
        super
      end
      
    end
  end
end