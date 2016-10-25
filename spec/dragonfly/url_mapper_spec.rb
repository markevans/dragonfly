# encoding: utf-8
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
      url_mapper.url_regexp.should == %r{\A/media(/[^\/\.]+?)?(/[^\/]+?)?(\-[^\/\-\.]+?)?(\.[^\.]+?)?\z}
    end
  end

  describe "url_for" do
    before(:each) do
      @url_mapper = Dragonfly::UrlMapper.new('/media/:job-:size')
    end

    it "should map correctly" do
      @url_mapper.url_for('job' => 'asdf', 'size' => '30x30').should == '/media/asdf-30x30'
    end

    it "should add extra params as query parameters" do
      @url_mapper.url_for('job' => 'asdf', 'size' => '30x30', 'when' => 'now').should == '/media/asdf-30x30?when=now'
    end

    it "should not worry if params aren't given" do
      @url_mapper.url_for('job' => 'asdf', 'when' => 'now', 'then' => 'soon').should match_url '/media/asdf?when=now&then=soon'
    end

    it "should call to_s on non-string values" do
      @url_mapper.url_for('job' => 'asdf', 'size' => 500).should == '/media/asdf-500'
    end

    it "should url-escape funny characters in the path" do
      @url_mapper.url_for('job' => 'a#c').should == '/media/a%23c'
    end

    it "should url-escape funny characters in the query string" do
      @url_mapper.url_for('bigjobs' => 'a#c').should == '/media?bigjobs=a%23c'
    end

    it "should url-escape the / character in a single segment" do
      @url_mapper.url_for('job' => 'a/c').should == '/media/a%2Fc'
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
      @url_mapper.params_for('/media/asdf', 'when=now').should == {'job' => 'asdf', 'when' => 'now'}
    end

    it "should generally be ok with wierd characters" do
      @url_mapper = Dragonfly::UrlMapper.new('/media/:doobie')
      @url_mapper.params_for('/media/sd sdf jl£@$ sdf:_', 'job=goodun').should == {'job' => 'goodun', 'doobie' => 'sd sdf jl£@$ sdf:_'}
    end

    it "should correctly url-unescape funny characters" do
      @url_mapper.params_for('/media/a%23c').should == {'job' => 'a#c'}
    end

    it "should work when the job contains the '-' character" do
      @url_mapper = Dragonfly::UrlMapper.new('/media/:job-:size.:format')
      @url_mapper.params_for('/media/asdf-30x30.jpg').should == {'job' => 'asdf', 'size' => '30x30', 'format' => 'jpg'}
      @url_mapper.params_for('/media/as-df-30x30.jpg').should == {'job' => 'as-df', 'size' => '30x30', 'format' => 'jpg'}
    end
  end

  describe "matching urls with standard format /media/:job/:name" do
    before(:each) do
      @url_mapper = Dragonfly::UrlMapper.new('/media/:job/:name')
    end

    {
      '' => nil,
      '/' => nil,
      '/media' => {'job' => nil, 'name' => nil},
      '/media/' => nil,
      '/moodia/asdf' => nil,
      '/media/asdf/' => nil,
      '/mount/media/asdf' => nil,
      '/media/asdf/stuff.egg' => {'job' => 'asdf', 'name' => 'stuff.egg'},
      '/media/asdf' =>           {'job' => 'asdf', 'name' => nil},
      '/media/asdf/stuff' =>     {'job' => 'asdf', 'name' => 'stuff'},
      '/media/asdf.egg' =>       {'job' => nil, 'name' => 'asdf.egg'},
      '/media/asdf/stuff/egg' => nil,
      '/media/asdf/stuff.dog.egg' => {'job' => 'asdf', 'name' => 'stuff.dog.egg'},
      '/media/asdf/s%3D2%2B-.d.e' => {'job' => 'asdf', 'name' => 's=2+-.d.e'},
      '/media/asdf-40x40/stuff.egg' => {'job' => 'asdf-40x40', 'name' => 'stuff.egg'},
      '/media/a%23c' => {'job' => 'a#c', 'name' => nil}
    }.each do |path, params|

      it "should turn the url #{path} into params #{params.inspect}" do
        @url_mapper.params_for(path).should == params
      end

      if params
        it "should turn the params #{params.inspect} into url #{path}" do
          @url_mapper.url_for(params).should == path
        end
      end

    end

  end

end
