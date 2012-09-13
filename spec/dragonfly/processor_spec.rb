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

  describe "update_url" do
    it "should do nothing if not defined on the added processor" do
      url_attributes = {}
      processor.add(:egg){|num| num + 1 }
      processor.update_url(:egg, {})
      url_attributes.should == {}
    end

    it "should call it on the added processor" do
      spoon = proc{}
      def spoon.update_url(attributes, a, b)
        attributes[:a] = a
        attributes[:b] = b
      end
      url_attributes = {}
      processor.add(:encode, spoon)
      processor.update_url(:encode, url_attributes, 3, 4)
      url_attributes.should == {:a => 3, :b => 4}
    end

    it "should raise an error if the processor doesn't exist" do
      expect{
        processor.update_url(:i_dont_exist, {})
      }.to raise_error(Dragonfly::Processor::NotDefined)
    end

  end

end
