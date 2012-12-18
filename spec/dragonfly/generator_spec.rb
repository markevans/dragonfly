require 'spec_helper'

describe Dragonfly::Generator do
  
  describe "adding generators" do
    let (:generator) { Dragonfly::Generator.new }
    let (:my_generator) { proc{ "BOO" } }

    it "adds the generator" do
      generator.add(:my_generator, my_generator)
      generator.generators[:my_generator].should == my_generator
    end
    it "adds a generator from a block" do
      generator.add(:my_generator, &my_generator)
      generator.generators[:my_generator].should == my_generator
    end
  end

  describe "#generate" do
    let (:generator) { Dragonfly::Generator.new }

    before :each do
      generator.add :my_generator do |num|
        "B" + "O" * num
      end
    end

    it "should use the generator when applied (converting content into a temp_object)" do
      temp_object = generator.generate(:my_generator, 3)
      temp_object.should be_a(Dragonfly::TempObject)
      temp_object.data.should == 'BOOO'
    end

    it "should raise an error if the generator doesn't exist" do
      expect{
        generator.generate(:goofy)
      }.to raise_error(Dragonfly::Generator::NoSuchGenerator)
    end

    it "should raise an error if there's a generating error" do
      class TestError < RuntimeError; end
      generator.add :goofy do |temp_object|
        raise TestError
      end
      expect{
        generator.generate(:goofy)
      }.to raise_error(Dragonfly::Generator::GenerationError) do |error|
        error.original_error.should be_a(TestError)
      end
    end

    it "should allow returning an array with extra attributes from the generator" do
      generator.add :goofy do |temp_object|
        ['hi', {'eggs' => 'asdf'}]
      end
      result = generator.generate(:goofy)
      result.data.should == 'hi'
      result.meta.should == {'eggs' => "asdf"}
    end
  end
  
  
end