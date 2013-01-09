require 'spec_helper'

describe Dragonfly::Processor do

  describe "#process" do
    let (:processor) { Dragonfly::Processor.new }

    before :each do
      processor.add :upcase do |temp_object, suffix=nil|
        "#{temp_object.data.upcase}#{suffix}"
      end
    end

    it "should use the processor when applied (converting content into a temp_object)" do
      temp_object = processor.process(:upcase, "baah", 'BA')
      temp_object.should be_a(Dragonfly::TempObject)
      temp_object.data.should == 'BAAHBA'
    end

    it "should raise an error if the processor doesn't exist" do
      expect{
        processor.process(:goofy, "baah", 'BA')
      }.to raise_error(Dragonfly::Processor::NotFound)
    end

    it "should raise an error if there's a processing error" do
      class TestError < RuntimeError; end
      processor.add :goofy do |temp_object|
        raise TestError
      end
      expect{
        processor.process(:goofy, "baah")
      }.to raise_error(Dragonfly::Processor::ProcessingError) do |error|
        error.original_error.should be_a(TestError)
      end
    end

    it "should maintain any TempObject meta attributes" do
      result = processor.process(:upcase, Dragonfly::TempObject.new("baah", 'name' => 'hello.txt', 'a' => 'b'))
      result.meta.should == {'name' => 'hello.txt', 'a' => 'b'}
    end

    it "should allow returning an array with extra attributes from the processor" do
      processor.add :goofy do |temp_object|
        ['hi', {'eggs' => 'asdf'}]
      end
      result = processor.process(:goofy, Dragonfly::TempObject.new("baah", 'a' => 'b'))
      result.data.should == 'hi'
      result.meta.should == {'a' => 'b', 'eggs' => "asdf"}
    end
  end

  describe "#update_url" do
    let (:processor) { Dragonfly::Processor.new }
    let (:processor_with_update_url) {
      processor = Object.new
      def processor.update_url(url_attrs, *args)
        url_attrs[:called] = true
      end
      processor
    }
    let (:processor_without_update_url) { Object.new }

    before :each do
      processor.add :p_with, processor_with_update_url
      processor.add :p_without, processor_without_update_url
    end

    it "should pass on update_url to the registered processor" do
      url_attrs = {}
      processor.update_url(:p_with, url_attrs, 'blarney')
      url_attrs.should == {:called => true}
    end

    it "should do nothing if the registered processor doesn't implement update_url" do
      url_attrs = {}
      processor.update_url(:p_without, url_attrs, 'blarney')
      url_attrs.should == {}
    end
  end

end
