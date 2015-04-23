require 'spec_helper'

describe "using the shell" do

  let (:app) { test_app }

  describe "shell injection" do
    it "should not allow it!" do
      app.configure_with(:imagemagick)
      begin
        app.generate(:plain, 10, 10, 'white').convert("-resize 5x5 ; touch tmp/stuff").apply
      rescue Dragonfly::Shell::CommandFailed
      end
      File.exist?('tmp/stuff').should be_falsey
    end
  end

  describe "env variables with imagemagick" do
    it "allows configuring the convert path" do
      app.configure_with(:imagemagick, :convert_command => '/bin/convert')
      app.shell.should_receive(:run).with(%r[/bin/convert], hash_including)
      app.create("").thumb('30x30').apply
    end

    it "allows configuring the identify path" do
      app.configure_with(:imagemagick, :identify_command => '/bin/identify')
      app.shell.should_receive(:run).with(%r[/bin/identify], hash_including).and_return("JPG 1 1")
      app.create("").width
    end
  end

end

