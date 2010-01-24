require File.dirname(__FILE__) + '/../spec_helper'

describe Dragonfly::AnalyserList do

  class EggHeads
    include Dragonfly::Delegatable
    def mime_type(temp_object)
      "text/eggnog"
    end
  end
  
  class Dingbats
    include Dragonfly::Delegatable
    def mime_type(temp_object)
      throw :unable_to_handle
    end
  end
  
  before(:each) do
    @analysers = Dragonfly::AnalyserList.new
  end
  
  describe "mime_type" do
    before(:each) do
      @temp_object = Dragonfly::TempObject.new 'asdfa'
    end
    it "should return the mime type as per usual if the registered analysers implement it" do
      @analysers.register(EggHeads)
      @analysers.mime_type(@temp_object).should == 'text/eggnog'
    end
    it "should return the mime_type as nil if the registered analysers don't implement it" do
      @analysers.mime_type(@temp_object).should be_nil
    end
    it "should return the mime_type as nil if the registered analysers throw :unable_to_handle" do
      @analysers.register(Dingbats)
      @analysers.mime_type(@temp_object).should be_nil
    end
  end
  
end
