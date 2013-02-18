require 'spec_helper'

describe Dragonfly::Register do

  let (:register) { Dragonfly::Register.new }
  let (:thing) { proc{ "BOO" } }

  it "adds an item" do
    register.add(:thing, thing)
    register.get(:thing).should == thing
  end

  it "adds from a block" do
    register.add(:thing, &thing)
    register.get(:thing).should == thing
  end

  it "raises an error if neither are given" do
    expect {
      register.add(:something)
    }.to raise_error(ArgumentError)
  end

  it "raises an error if getting one that doesn't exist" do
    expect {
      register.get(:thing)
    }.to raise_error(Dragonfly::Register::NotFound)
  end

  it "allows getting with a string" do
    register.add(:thing, thing)
    register.get('thing').should == thing
  end

end
