require "spec_helper"
require "dragonfly/param_validators"

describe Dragonfly::ParamValidators do
  include Dragonfly::ParamValidators

  describe "validate!" do
    it "does nothing if the parameter meets the condition" do
      validate!("thing") { |t| t === "thing" }
    end

    it "raises if the parameter doesn't meet the condition" do
      expect {
        validate!("thing") { |t| t === "ting" }
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end

    it "does nothing if the parameter is nil" do
      validate!(nil) { |t| t === "thing" }
    end
  end

  describe "validate_all!" do
    it "allows passing an array of parameters to validate" do
      validate_all!(["a", "b"]) { |p| /\w/ === p }
      expect {
        validate_all!(["a", " "]) { |p| /\w/ === p }
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end
  end

  describe "validate_all_keys!" do
    it "allows passing an array of parameters to validate" do
      obj = { "a" => "A", "b" => "B" }
      validate_all_keys!(obj, ["a", "b"]) { |p| /\w/ === p }
      expect {
        validate_all_keys!(obj, ["a", "b"]) { |p| /[a-z]/ === p }
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end
  end

  describe "is_number" do
    [3, 3.14, "3", "3.2"].each do |val|
      it "validates #{val.inspect}" do
        validate!(val, &is_number)
      end
    end

    ["", "3 2", "hello4", {}, []].each do |val|
      it "validates #{val.inspect}" do
        expect {
          validate!(val, &is_number)
        }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
      end
    end
  end

  describe "is_word" do
    ["hello", "helLo", "HELLO"].each do |val|
      it "validates #{val.inspect}" do
        validate!(val, &is_word)
      end
    end

    ["", "hel%$lo", "hel lo", "hel-lo", {}, []].each do |val|
      it "validates #{val.inspect}" do
        expect {
          validate!(val, &is_word)
        }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
      end
    end
  end

  describe "is_words" do
    ["hello there", "Hi", "  What is Up "].each do |val|
      it "validates #{val.inspect}" do
        validate!(val, &is_words)
      end
    end

    ["", "hel%$lo", "What's up", "hel-lo", {}, []].each do |val|
      it "validates #{val.inspect}" do
        expect {
          validate!(val, &is_words)
        }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
      end
    end
  end
end
