require 'spec_helper'
require 'pathname'

describe Dragonfly::ImageMagick::CommandLine do

  let (:command_line) { Dragonfly::ImageMagick::CommandLine.new }

  it "provides defaults" do
    command_line.convert_command.should == "convert"
    command_line.identify_command.should == "identify"
  end

  it "allows setting" do
    command_line.convert_command = '/bin/convert'
    command_line.convert_command.should == "/bin/convert"

    command_line.identify_command = "/bin/identify"
    command_line.identify_command.should == "/bin/identify"
  end
end
