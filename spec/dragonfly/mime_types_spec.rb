require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::MimeTypes do
  
  describe "mime_type_for" do

    [:png, 'png', '.png'].each do |ext|
      it "should return the mime type for an extension passed in as #{ext.inspect}" do
        Dragonfly::MimeTypes.mime_type_for(ext).should == 'image/png'
      end
    end
    
  end

  describe "extension_for" do
    it "should return the extension for the given mime type" do
      Dragonfly::MimeTypes.extension_for('image/png').should == 'png'
    end
  end
  
end