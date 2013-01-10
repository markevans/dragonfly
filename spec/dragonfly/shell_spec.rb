require 'spec_helper'

describe Dragonfly::Shell do

  let(:shell){ Dragonfly::Shell.new }

  it "returns the result of the command" do
    shell.run("echo 10").strip.should == '10'
  end

  it "should raise an error if the command isn't found" do
    suppressing_stderr do
      lambda{
        shell.run "non-existent-command"
      }.should raise_error(Dragonfly::Shell::CommandFailed)
    end
  end

  it "should raise an error if the command fails" do
    suppressing_stderr do
      lambda{
        shell.run "ls -j"
      }.should raise_error(Dragonfly::Shell::CommandFailed)
    end
  end

  describe "escaping args" do
    {
      %q(hello) => %q('hello'),
      %q("hello") => %q('hello'),
      %q('hello') => %q('hello'),
      %q(he\'llo) => %q('he'\''llo'),
      %q('he'\''llo') => %q('he'\''llo'),
      %q("he'llo") => %q('he'\''llo'),
      %q(hel$(lo)) => %q('hel$(lo)'),
      %q(hel\$(lo)) => %q('hel$(lo)'),
      %q('hel\$(lo)') => %q('hel\$(lo)')
    }.each do |args, escaped_args|
      it "should escape #{args.inspect} -> #{escaped_args.inspect}" do
        pending "not applicable to windows" if Dragonfly.running_on_windows?
        shell.escape_args(args).should == escaped_args
      end
    end
  end
  
end
