require 'spec_helper'

describe Dragonfly do
  it "returns a default app" do
    Dragonfly.default_app.should == Dragonfly::App.instance
  end
end

