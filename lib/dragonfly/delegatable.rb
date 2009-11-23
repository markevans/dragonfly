module Dragonfly
  module Delegatable

    def delegatable_methods
      if @delegatable_methods
        @delegatable_methods
      else
        ancestors = self.class.ancestors
        @delegatable_methods = ancestors[0...ancestors.index(Delegatable)].map{|i| i.instance_methods(false) }.flatten
      end
    end

  end
end