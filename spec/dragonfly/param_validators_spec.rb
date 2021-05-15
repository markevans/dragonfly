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

    it "works with a regexp" do
      validate!("thing", /thing/)
      expect {
        validate!("thing", /ting/)
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end
  end

  describe "validate_all!" do
    it "allows passing an array of parameters to validate" do
      validate_all!(["a", "b"], /\w/)
      expect {
        validate_all!(["a", " "], /\w/)
      }.to raise_error(Dragonfly::ParamValidators::InvalidParameter)
    end
  end
end
