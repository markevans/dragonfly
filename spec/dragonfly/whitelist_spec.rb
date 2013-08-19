require 'spec_helper'

describe Dragonfly::Whitelist do
  it "matches regexps" do
    whitelist = Dragonfly::Whitelist.new([/platipus/])
    whitelist.include?("platipus").should be_true
    whitelist.include?("small platipus in the bath").should be_true
    whitelist.include?("baloney").should be_false
  end

  it "matches strings" do
    whitelist = Dragonfly::Whitelist.new(["platipus"])
    whitelist.include?("platipus").should be_true
    whitelist.include?("small platipus in the bath").should be_false
    whitelist.include?("baloney").should be_false
  end

  it "only needs one match" do
    Dragonfly::Whitelist.new(%w(a b)).include?("c").should be_false
    Dragonfly::Whitelist.new(%w(a b c)).include?("c").should be_true
  end
end

