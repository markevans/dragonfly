require 'spec_helper'

describe Dragonfly::Register do
  
  let(:register) { Dragonfly::Register.new }

  describe "registering processors" do
    let(:func){ proc{ "HELLO" } }

    it "should allow registering procs" do
      register.add :hello, func
      register.items.should == {:hello => func}
    end

    it "should allow registering using block syntax" do
      register.add(:hello, &func)
      register.items.should == {:hello => func}
    end

    it "allows registering multiple methods of an object" do
      processor = Object.new
      class << processor
        def resize(*args)
          "resized"
        end

        def shrink(*args)
          "shrunk"
        end
      end
      register.delegate_to(processor, [:resize, :shrink])
      register.item_names.should == [:resize, :shrink]
      register[:resize].call.should == 'resized'
      register[:shrink].call.should == 'shrunk'
    end
  end

end
