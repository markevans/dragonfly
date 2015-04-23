require 'spec_helper'

describe Dragonfly::Utils do

  describe "blank?" do
    [
      nil,
      false,
      "",
      [],
      {}
    ].each do |obj|
      it "returns true for #{obj.inspect}" do
        obj.blank?.should be_truthy
      end
    end

    [
      "a",
      [1],
      {1 => 2},
      Object.new,
      true,
      7.3
    ].each do |obj|
      it "returns false for #{obj.inspect}" do
        obj.blank?.should be_falsey
      end
    end
  end

end
