require File.dirname(__FILE__) + '/../../spec_helper'

png_path = File.dirname(__FILE__) + '/../../../samples/egg.png'

describe Dragonfly::Analysis::FileCommandAnalyser do
  
  before(:each) do
    @analyser = Dragonfly::Analysis::FileCommandAnalyser.new
  end
  
  describe "mime_type" do
    
    describe "when using the filesystem" do
      before(:each) do
        @analyser.use_filesystem = true
        @temp_object = Dragonfly::TempObject.new(File.new(png_path))
      end
      it "should give the mime-type" do
        @analyser.mime_type(@temp_object).should == 'image/png'
      end
      it "should not have initialized the data string" do
        @analyser.mime_type(@temp_object)
        @temp_object.instance_eval{@data}.should be_nil
      end
    end
    
    describe "when not using the filesystem" do
      before(:each) do
        @analyser.use_filesystem = false
        @temp_object = Dragonfly::TempObject.new(File.read(png_path))
      end
      it "should give the mime-type" do
        @analyser.mime_type(@temp_object).should == 'image/png'
      end
      it "should not have initialized the file" do
        @analyser.mime_type(@temp_object)
        @temp_object.instance_eval{@tempfile}.should be_nil
      end
      
      {
        :jpg => 'image/jpeg',
        :png => 'image/png',
        :gif => 'image/gif',
        :tif => 'image/tiff'
      }.each do |format, mime_type|
        it "should work properly (without a broken pipe error) for big files of format #{format}" do
          data = Dragonfly::Generation::RMagickGenerator.new.plasma(1000, 1000, format).first
          temp_object = Dragonfly::TempObject.new(data)
          @analyser.mime_type(temp_object).should == mime_type
        end
      end
      
    end
  
  end
  
end