module Dragonfly
  module Delegatable

    def self.included(klass)

      class << klass
        def delegatable_methods
          @delegatable_methods ||= []
        end

        def method_added(method)
          delegatable_methods << method.to_s
        end
      end
      
    end
    
  end
end