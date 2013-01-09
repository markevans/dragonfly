require 'spec_helper'

describe Dragonfly::Generator do

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
      }.to raise_error(Dragonfly::Generator::NotFound)
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

  describe "#update_url" do
    let (:generator) { Dragonfly::Generator.new }
    let (:generator_with_update_url) {
      generator = Object.new
      def generator.update_url(url_attrs, *args)
        url_attrs[:called_with] = args
      end
      generator
    }
    let (:generator_without_update_url) { Object.new }

    before :each do
      generator.add :g_with, generator_with_update_url
      generator.add :g_without, generator_without_update_url
    end

    it "should pass on update_url to the registered generator" do
      url_attrs = {}
      generator.update_url(:g_with, url_attrs, 'blarney')
      url_attrs.should == {:called_with => ['blarney']}
    end

    it "should do nothing if the registered generator doesn't implement update_url" do
      url_attrs = {}
      generator.update_url(:g_without, url_attrs, 'blarney')
      url_attrs.should == {}
    end

  end
end
