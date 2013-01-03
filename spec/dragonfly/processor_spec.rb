require 'spec_helper'

describe Dragonfly::Processor do

  describe "adding processors" do
    let (:processor) { Dragonfly::Processor.new }
    let (:upcase_processor) { proc{} }

    it "adds the processor" do
      processor.add(:upcase, upcase_processor)
      processor.processors[:upcase].should == upcase_processor
    end
    it "adds a processor from a block" do
      processor.add(:upcase, &upcase_processor)
      processor.processors[:upcase].should == upcase_processor
    end
    it "raises an error if neither are given" do
      expect {
        processor.add(:upcase)
      }.to raise_error(ArgumentError)
    end
  end

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
      }.to raise_error(Dragonfly::Processor::NoSuchProcessor)
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

  describe "building processors" do
    let (:processor) { Dragonfly::Processor.new }

    before :each do
      processor.add(:thumb) {|temp_object, size| temp_object.data + "-thumb-#{size}" }
      processor.add(:encode) {|temp_object, format| temp_object.data + "-encoded-#{format}" }
      processor.build :thumcode do |size, format|
        process :thumb, size
        process :encode, format
      end
    end

    it "builds a new processor" do
      result = processor.process(:thumcode, 'smarties', 4, 'jpg')
      result.data.should == "smarties-thumb-4-encoded-jpg"
    end

    it "deals correctly with update_url" do
      thumb_processor = processor.processors[:thumcode]
      def thumb_processor.update_url(url_attrs, size, format)
        url_attrs[:size] = size
      end
      url_attrs = {}
      processor.update_url(:thumcode, url_attrs, 4, 'jpg')
      url_attrs.should == {:size => 4}
    end

  end

end
