require 'spec_helper'

describe Dragonfly::Processor do

  describe "#process" do
    let (:processor) { Dragonfly::Processor.new }

    it "uses the processor when applied" do
      upcase_processor = processor.add(:upcase){}
      content = mock('content')

      upcase_processor.should_receive(:call).with(content, 'BA')
      processor.process(:upcase, content, 'BA')
    end

    it "raises an error if the processor doesn't exist" do
      expect{
        processor.process(:goofy, mock('content'), 'BA')
      }.to raise_error(Dragonfly::Processor::NotFound)
    end

    it "raises an error if there's a processing error" do
      class TestError < RuntimeError; end
      processor.add :goofy do
        raise TestError
      end
      expect{
        processor.process(:goofy, mock('content'))
      }.to raise_error(Dragonfly::Processor::ProcessingError) do |error|
        error.original_error.should be_a(TestError)
      end
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

