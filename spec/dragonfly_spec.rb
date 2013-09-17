require 'spec_helper'
require 'logger'
require 'stringio'

describe Dragonfly do
  it "returns a default app" do
    Dragonfly.app.should == Dragonfly::App.instance
  end

  it "returns a named app" do
    Dragonfly.app(:mine).should == Dragonfly::App.instance(:mine)
  end

  describe "logging" do
    before do
      Dragonfly.logger = Logger.new(StringIO.new)
    end

    it "debugs" do
      Dragonfly.logger.should_receive(:debug).with(/something/)
      Dragonfly.debug("something")
    end

    it "warns" do
      Dragonfly.logger.should_receive(:warn).with(/something/)
      Dragonfly.warn("something")
    end

    it "shows info" do
      Dragonfly.logger.should_receive(:info).with(/something/)
      Dragonfly.info("something")
    end
  end

  describe "deprecations" do
    it "raises a message when using Dragonfly[:name]" do
      expect {
        Dragonfly[:images]
      }.to raise_error(/deprecated/)
    end
  end
end

