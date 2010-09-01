require File.dirname(__FILE__) + '/../../spec_helper'

describe Dragonfly::Analysis::RMagickAnalyser do
  
  before(:each) do
    image_path = File.dirname(__FILE__) + '/../../../samples/beach.png'
    @beach = Dragonfly::TempObject.new(File.new(image_path))
    @analyser = Dragonfly::Analysis::RMagickAnalyser.new
    @analyser.log = Logger.new(LOG_FILE)
  end

  describe "analysis methods", :shared => true do
    
    it "should return the width" do
      @analyser.width(@beach).should == 280
    end
  
    it "should return the height" do
      @analyser.height(@beach).should == 355
    end
  
    it "should return the aspect ratio" do
      @analyser.aspect_ratio(@beach).should == (280.0/355.0)
    end
  
    it "should say if it's portrait" do
      @analyser.portrait?(@beach).should be_true
    end
  
    it "should say if it's landscape" do
      @analyser.landscape?(@beach).should be_false
    end
  
    it "should return the number of colours" do
      @analyser.number_of_colours(@beach).should == 34703
    end
  
    it "should return the depth" do
      @analyser.depth(@beach).should == 8
    end
  
    it "should return the format" do
      @analyser.format(@beach).should == :png
    end
    
  end
  
  describe "when using the filesystem" do
    before(:each) do
      @analyser.use_filesystem = true
    end
    it_should_behave_like "analysis methods"
  end
  
  describe "when not using the filesystem" do
    before(:each) do
      @analyser.use_filesystem = false
    end
    it_should_behave_like "analysis methods"
  end
  
  %w(width height aspect_ratio number_of_colours depth format portrait? landscape?).each do |meth|
    it "should throw unable_to_handle in #{meth.inspect} if it's not an image file" do
      temp_object = Dragonfly::TempObject.new('blah')
      lambda{
        @analyser.send(meth, temp_object)
      }.should throw_symbol(:unable_to_handle)
    end
  end
  
end
