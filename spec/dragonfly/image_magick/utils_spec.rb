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

  it "should work for commands with parenthesis" do
    expect { @obj.send(:run, "\\( +clone -sparse-color Barycentric '0,0 black 0,%[fx:h-1] white' -function polynomial 2,-2,0.5 \\) -compose Blur -set option:compose:args 15 -composite") }.to_not raise_error
  end

end
