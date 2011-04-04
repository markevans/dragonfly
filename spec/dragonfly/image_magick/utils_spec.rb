require 'spec_helper'

describe Dragonfly::ImageMagick::Utils do

  before(:each) do
    @obj = Object.new
    @obj.extend(Dragonfly::ImageMagick::Utils)
  end
  
  it "should raise an error if the identify command isn't found" do
    suppressing_stderr do
      lambda{
        @obj.send(:run, "non-existent-command")
      }.should raise_error(Dragonfly::ImageMagick::Utils::ShellCommandFailed)
    end
  end

end
