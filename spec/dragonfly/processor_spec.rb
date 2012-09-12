require 'spec_helper'

describe Dragonfly::Processor do
  
  let(:processor) { Dragonfly::Processor.new }

  describe "registering processors" do
    let(:func){ proc{ "HELLO" } }

    it "should allow registering procs" do
      processor.add :hello, func
      processor.processors.should == {:hello => func}
    end

    it "should allow registering using block syntax" do
      processor.add(:hello, &func)
      processor.processors.should == {:hello => func}
    end
  end

  describe "process" do
    it "should correctly call a registered block" do
      processor.add(:egg){|num| num + 1 }
      processor.process(:egg, 4).should == 5
    end
    
    it "should correctly call an object that responds to 'call'" do
      obj = Object.new
      def obj.call(num); num - 3; end
      processor.add(:spoon, obj)
      processor.process(:spoon, 4).should == 1
    end

    describe "errors" do
      it "should raise an for if the processor doesn't exist" do
        expect{
          processor.process(:i_dont_exist, "")
        }.to raise_error(Dragonfly::Processor::NotDefined)
      end
      
      it "should raise an error if the processor raises an error" do
        bad_processor = proc{}
        bang = RuntimeError.new("baloney!")
        processor.add :blah, bad_processor
        bad_processor.should_receive(:call).and_raise(bang)
        expect{
          processor.process(:blah, "yibble")
        }.to raise_error(Dragonfly::Processor::ProcessingError){|error|
          error.original_error.should == bang
        }
      end
    end
  end

end
