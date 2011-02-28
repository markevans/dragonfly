require 'spec_helper'

describe Dragonfly::UrlMapper do

  describe "validating the url format" do
    it "should be ok with a valid one" do
      Dragonfly::UrlMapper.new('/media/:job/:name')
    end
    it "should throw an error if params aren't separated" do
      lambda{
        Dragonfly::UrlMapper.new('/media/:job:name')
      }.should raise_error(Dragonfly::UrlMapper::BadUrlFormat)
    end
  end

  describe "params_in_url" do
    it "should return everything specified in the url" do
      url_mapper = Dragonfly::UrlMapper.new('/media/:job/:basename.:ext')
      url_mapper.params_in_url.should == ['job', 'basename', 'ext']
    end
  end
  
  describe "url_regexp" do
    it "should return a regexp with non-greedy optional groups that include the preceding slash/dot/dash" do
      url_mapper = Dragonfly::UrlMapper.new('/media/:job/:basename-:size.:format')
      url_mapper.url_regexp.should == %r{^/media(/[\w_]+?)?(/[\w_]+?)?(\-[\w_]+?)?(\.[\w_]+?)?$}
    end
    
    it "should allow setting custom patterns in the url" do
      url_mapper = Dragonfly::UrlMapper.new('/media/:job-:size.:format', :job => '\w', :size => '\d', :format => '[^\.]')
      url_mapper.url_regexp.should == %r{^/media(/\w+?)(\-\d+?)(\.[^\.]+?)$}
    end
    
    it "should make optional match patterns (ending in ?) apply to the whole group including the preceding seperator" do
      url_mapper = Dragonfly::UrlMapper.new('/media/:job', :job => '\w?')
      url_mapper.url_regexp.should == %r{^/media(/\w+?)?$}
    end
  end

  describe "url_for" do
    before(:each) do
      @url_mapper = Dragonfly::UrlMapper.new('/media/:job')
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
      @url_mapper = Dragonfly::UrlMapper.new('/media/:job')
    end
    
    it "should map correctly" do
      @url_mapper.params_for('/media/asdf').should == {'job' => 'asdf'}
    end
    
    it "should include query parameters" do
      @url_mapper.params_for('/media/asdf?when=now').should == {'job' => 'asdf', 'when' => 'now'}
    end
  end

  describe "matching urls with standard format /media/:job/:basename.:format" do
    before(:each) do
      @url_mapper = Dragonfly::UrlMapper.new('/media/:job/:basename.:format',
        :job => '\w',
        :basename => '[^\/]?',
        :format => '[^\.]?'
      )
    end

    {
      '' => nil,
      '/' => nil,
      '/media' => nil,
      '/media/' => nil,
      '/moodia/asdf' => nil,
      '/media/asdf/' => nil,
      '/mount/media/asdf' => nil,
      '/media/asdf/stuff.egg' => {'job' => 'asdf', 'basename' => 'stuff', 'format' => 'egg'},
      '/media/asdf' =>           {'job' => 'asdf', 'basename' => nil,     'format' => nil},
      '/media/asdf/stuff' =>     {'job' => 'asdf', 'basename' => 'stuff', 'format' => nil},
      '/media/asdf.egg' =>       {'job' => 'asdf', 'basename' => nil,     'format' => 'egg'},
      '/media/asdf/stuff/egg' => nil,
      '/media/asdf/stuff.dog.egg' => {'job' => 'asdf', 'basename' => 'stuff.dog', 'format' => 'egg'},
      '/media/asdf/s=2 -.d.e' => {'job' => 'asdf', 'basename' => 's=2 -.d', 'format' => 'e'},
      '/media/asdf-40x40/stuff.egg' => nil
    }.each do |url, params|
      it "should return the url #{url} into params #{params.inspect}" do
        @url_mapper.params_for(url).should == params
      end    
    end

  end
  
end
