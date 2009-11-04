require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::MimeTypes do
  
  describe "mime_type_for" do

    [:png, 'png', '.png'].each do |ext|
      it "should return the mime type for an extension passed in as #{ext.inspect}" do
        Dragonfly::MimeTypes.mime_type_for(ext).should == 'image/png'
      end
    end
    
    it "should raise an exception if it can't find the mime-type for an extension" do
      lambda{
        Dragonfly::MimeTypes.mime_type_for('googoo')
      }.should raise_error(Dragonfly::MimeTypes::MimeTypeNotFound)
    end
    
  end

  describe "extension_for" do
    
    it "should return the extension for the given mime type" do
      Dragonfly::MimeTypes.extension_for('image/png').should == 'png'
    end
    
    it "should raise an exception if it can't find the extension for a mime-type" do
      lambda{
        Dragonfly::MimeTypes.extension_for('gooby/doo')
      }.should raise_error(Dragonfly::MimeTypes::MimeTypeNotFound)      
    end
    
  end
  
end