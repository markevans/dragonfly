require File.dirname(__FILE__) + '/spec_helper'

describe "Dragonfly" do
  
  it "should return RMagickConfiguration as Config::RMagickImages, with a deprecation warning" do
    Dragonfly.should_receive(:puts).with(string_matching(/WARNING/))
    Dragonfly::RMagickConfiguration.should == Dragonfly::Config::RMagickImages
  end
  
  it "should raise an error for other undefined constants" do
    lambda{
      Dragonfly::Eggheads
    }.should raise_error(NameError)
  end
  
end
