require 'spec_helper'

describe Dragonfly::ImageMagickUtils do

  before(:each) do
    @obj = Object.new
    @obj.extend(Dragonfly::ImageMagickUtils)
  end
  
  it "should raise an error if the identify command isn't found" do
    lambda{
      @obj.send(:run, "non-existent-command")
    }.should raise_error(Dragonfly::ImageMagickUtils::ShellCommandFailed)
  end

end
