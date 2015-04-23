require 'spec_helper'

describe Dragonfly::Whitelist do
  it "matches regexps" do
    whitelist = Dragonfly::Whitelist.new([/platipus/])
    whitelist.include?("platipus").should be_truthy
    whitelist.include?("small platipus in the bath").should be_truthy
    whitelist.include?("baloney").should be_falsey
  end

  it "matches strings" do
    whitelist = Dragonfly::Whitelist.new(["platipus"])
    whitelist.include?("platipus").should be_truthy
    whitelist.include?("small platipus in the bath").should be_falsey
    whitelist.include?("baloney").should be_falsey
  end

  it "only needs one match" do
    Dragonfly::Whitelist.new(%w(a b)).include?("c").should be_falsey
    Dragonfly::Whitelist.new(%w(a b c)).include?("c").should be_truthy
  end

  it "allows pushing" do
    whitelist = Dragonfly::Whitelist.new(["platipus"])
    whitelist.push("duck")
    whitelist.should include "platipus"
    whitelist.should include "duck"
  end
end

