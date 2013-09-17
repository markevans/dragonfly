require 'dragonfly/model/instance_methods'
require 'dragonfly/model/class_methods'

module Dragonfly
  module Model

    def self.extended(klass)
      unless klass.include?(InstanceMethods)
        klass.extend(ClassMethods)
        klass.class_eval{ include InstanceMethods }
      end
    end

  end
end
