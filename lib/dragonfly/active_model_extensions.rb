module Dragonfly

  module ActiveModelExtensions

    def self.extended(klass)
      unless klass.include?(InstanceMethods)
        klass.extend(ClassMethods)
        klass.class_eval{ include InstanceMethods }
      end
    end

  end
end