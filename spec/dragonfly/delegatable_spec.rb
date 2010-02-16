require File.dirname(__FILE__) + '/../spec_helper'

module M
  def m; end
end

class A
  include Dragonfly::Delegatable
  def a; end
end

class B < A
  include M
  def b; end
end

describe Dragonfly::Delegatable do
  
  describe "delegatable_methods" do
    it "should include all methods defined after including, including mixed-in and inherited" do
      B.new.delegatable_methods.should == [:b, :m, :a].map{|m| m.to_method_name }
    end
    
    it "should work the second (cached) time" do
      b = B.new
      b.delegatable_methods
      b.delegatable_methods.should == [:b, :m, :a].map{|m| m.to_method_name }
    end
    
  end
  
end