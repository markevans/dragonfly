require 'spec_helper'

describe Dragonfly do
  it "returns a default app" do
    Dragonfly.app.should == Dragonfly::App.instance
  end

  it "returns a named app" do
    Dragonfly.app(:mine).should == Dragonfly::App.instance(:mine)
  end
end

