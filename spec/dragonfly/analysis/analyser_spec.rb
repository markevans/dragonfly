require File.dirname(__FILE__) + '/../../spec_helper'

class ImageAnalyser < Dragonfly::Analysis::Base

  def width(temp_object)
    temp_object.data.length
  end

  def mime_type(temp_object)
    return 'image/fart' if temp_object.data == 'THIS IS AN IMAGE'
    return 'image/pdf' if temp_object.data == 'THIS IS A PDF'
  end

end

class PdfAnalyser < Dragonfly::Analysis::Base

  def pdf_type(temp_object)
    'egg'
  end

  def mime_type(temp_object)
    'application/pdf' if temp_object.data == 'THIS IS A PDF'
  end

end

describe Dragonfly::Analysis::Analyser do
  
  describe "mime_type" do
    
    before(:each) do
      @analyser = Dragonfly::Analysis::Analyser.new
      @image = Dragonfly::TempObject.new("THIS IS AN IMAGE")
      @pdf = Dragonfly::TempObject.new("THIS IS A PDF")
    end
    
    describe "when no analysers have been registered" do

      it "should return nil when no modules have been registered" do
        @analyser.mime_type(@image).should be_nil
      end

      it "should should return analysis methods as an empty array" do
        @analyser.analysis_methods.should == []
      end
      
    end
    
    describe "after registering a number of modules" do

      before(:each) do
        @analyser.register(ImageAnalyser.new)
        @analyser.register(PdfAnalyser.new)
      end

      it "should return the correct value when one of the modules returns non-nil" do
        @analyser.mime_type(@image).should == 'image/fart'
      end
    
      it "should override the first registered modules's value with the second, when they both return non-nil" do
        @analyser.mime_type(@pdf).should == 'application/pdf'
      end

      it "should return all the analysis methods" do
        @analyser.analysis_methods.sort.should == ['mime_type', 'pdf_type', 'width']
      end
      
      it "should say if if has an analysis method (as a symbol)" do
        @analyser.has_analysis_method?('pdf_type').should be_true
      end

      it "should say if if has an analysis method (as a string)" do
        @analyser.has_analysis_method?(:pdf_type).should be_true
      end

      it "should delegate the call of a method to the registered analysers" do
        @analyser.width(@image).should == 16
      end

    end
    
  end
  
end