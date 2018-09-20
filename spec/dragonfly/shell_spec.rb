require 'spec_helper'

describe Dragonfly::Shell do

  let(:shell){ Dragonfly::Shell.new }

  it "returns the result of the command" do
    shell.run(['echo', '10']).strip.should == '10'
  end

  it "should raise an error if the command isn't found" do
    lambda{
      shell.run ['non-existent-command']
    }.should raise_error(Errno::ENOENT)
  end

  it "should raise an error if the command fails" do
    lambda{
      shell.run ['ls', '-j']
    }.should raise_error(Dragonfly::Shell::CommandFailed)
  end

  it "escapes commands by default" do
    shell.run(['echo', '`echo 1`']).strip.should == "`echo 1`"
  end

end
