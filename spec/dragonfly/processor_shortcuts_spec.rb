require 'spec_helper'

describe Dragonfly::ProcessorShortcuts do

  describe "defining processors" do

    before(:each) do
      @processor_shortcuts = Dragonfly::ProcessorShortcuts.new
      @object = Object.new
      @object.extend @processor_shortcuts
    end

    describe "a simple job" do

      before(:each) do
        @processor_shortcuts.add :thumb do |size|
          process :thumb, size
        end
      end

      it "correctly call process steps" do
        @object.should_receive(:process).with(:thumb, '30x30#').and_return(job=mock)
        @object.thumb('30x30#').should == job
      end

      it "should correctly call process steps when bang is given" do
        @object.should_receive(:process!).with(:thumb, '30x30#').and_return(@object)
        @object.thumb!('30x30#').should == @object
      end

    end

  end
  
  
  describe "#names" do
    
    before(:each) do
      @processor_shortcuts = Dragonfly::ProcessorShortcuts.new
      @object = Object.new
      @object.extend @processor_shortcuts
    end
    
    it "should provide an empty list when no jobs have been defined" do
      @processor_shortcuts.names.should == []
    end
    
    it "should contain the job name when one is defined" do
      @processor_shortcuts.add :foo do |size|
        process :thumb, size
      end
      @processor_shortcuts.names.should eq [:foo]
    end
    
  end
  
end
