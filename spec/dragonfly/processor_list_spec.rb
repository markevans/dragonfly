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
  end

end
