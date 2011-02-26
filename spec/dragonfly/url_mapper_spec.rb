require 'spec_helper'

describe Dragonfly::UrlMapper do
  
  before(:each) do
    @url_mapper = Dragonfly::UrlMapper.new
  end
  
  describe "url_for" do
    before(:each) do
      @url_mapper.url_format = '/media/:job'
    end
    
    it "should map correctly" do
      @url_mapper.url_for('job' => 'asdf').should == '/media/asdf'
    end
    
    it "should add extra params as query parameters" do
      @url_mapper.url_for('job' => 'asdf', 'when' => 'now').should == '/media/asdf?when=now'
    end
    
    it "should raise an error if required params aren't given" do
      lambda{
        @url_mapper.url_for('when' => 'now')
      }.should raise_error(Dragonfly::UrlMapper::MissingParams)      
    end
  end

  describe "params_for" do
    before(:each) do
      @url_mapper.url_format = '/media/:job'
    end
    
    it "should map correctly" do
      @url_mapper.params_for('/media/asdf').should == {'job' => 'asdf'}
    end
    
    it "should include query parameters" do
      @url_mapper.params_for('/media/asdf?when=now').should == {'job' => 'asdf', 'when' => 'now'}
    end

    [
      '',
      '/',
      '/media',
      '/media/',
      '/moodia/asdf',
      '/media/asdf/',
      '/media/asdf/stuff',
      '/mount/media/asdf'
    ].each do |url|
      it "should return nil if the url doesn't match, e.g. #{url}" do
        @url_mapper.params_for(url).should be_nil
      end    
    end
  end
  
end
