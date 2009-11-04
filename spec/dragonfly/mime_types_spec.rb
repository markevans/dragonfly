require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::MimeTypes do
  
  after(:each) do
    Dragonfly::MimeTypes.clear_custom_mime_types!
  end
  
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
  
  describe "registering mime-types" do
    
    describe "when neither mime type or extension are previously known" do
      before(:each){ Dragonfly::MimeTypes.register('image/goo', 'goo') }
      it { Dragonfly::MimeTypes.mime_type_for('goo').should == 'image/goo' }
      it { Dragonfly::MimeTypes.extension_for('image/goo').should == 'goo' }
    end

    describe "when file extension isn't previously known" do
      before(:each){ Dragonfly::MimeTypes.register('image/gif', 'doobie') }
      it { Dragonfly::MimeTypes.mime_type_for('doobie').should == 'image/gif' }
      it { Dragonfly::MimeTypes.mime_type_for('gif').should == 'image/gif' }
      it { Dragonfly::MimeTypes.extension_for('image/gif').should == 'doobie' }
    end

    describe "when mime type isn't previously known" do
      before(:each){ Dragonfly::MimeTypes.register('image/dooboo', 'jpg') }
      it { Dragonfly::MimeTypes.mime_type_for('jpg').should == 'image/dooboo' }
      it { Dragonfly::MimeTypes.extension_for('image/dooboo').should == 'jpg' }
    end
    
    describe "clearing custom mime-types" do
      it {
        Dragonfly::MimeTypes.register('image/gif', 'doobie')
        Dragonfly::MimeTypes.clear_custom_mime_types!
        Dragonfly::MimeTypes.extension_for('image/gif').should == 'gif'
      }
    end

  end
  
end