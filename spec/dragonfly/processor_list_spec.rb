require 'spec_helper'

describe Dragonfly::ProcessorList do
  
  let(:processor_list) { Dragonfly::ProcessorList.new }

  describe "registering processors" do
    let(:func){ proc{ "HELLO" } }

    it "should allow registering procs" do
      processor_list.add :hello, func
      processor_list.processors.should == {:hello => func}
    end

    it "should allow registering using block syntax" do
      processor_list.add(:hello, &func)
      processor_list.processors.should == {:hello => func}
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
      processor_list.delegate_to(processor, [:resize, :shrink])
      processor_list.processor_names.should == [:resize, :shrink]
      processor_list[:resize].call.should == 'resized'
      processor_list[:shrink].call.should == 'shrunk'
    end
  end

end
