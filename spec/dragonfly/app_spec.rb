require File.dirname(__FILE__) + '/../spec_helper'
require 'rack/mock'

def request(app, path)
  Rack::MockRequest.new(app).get(path)
end

describe Dragonfly::App do

  describe ".instance" do
    
    it "should create a new instance if it didn't already exist" do
      app = Dragonfly::App.instance(:images)
      app.should be_a(Dragonfly::App)
    end
    
    it "should return an existing instance if called by name" do
      app = Dragonfly::App.instance(:images)
      Dragonfly::App.instance(:images).should == app
    end
    
    it "should also work using square brackets" do
      Dragonfly[:images].should == Dragonfly::App.instance(:images)
    end
    
  end
  
  describe ".new" do
    it "should not be callable" do
      lambda{
        Dragonfly::App.new
      }.should raise_error(NoMethodError)
    end
  end

  describe "mime types" do
    describe "#mime_type_for" do
      before(:each) do
        @app = test_app
      end
      it "should return the correct mime type for a symbol" do
        @app.mime_type_for(:png).should == 'image/png'
      end
      it "should work for strings" do
        @app.mime_type_for('png').should == 'image/png'
      end
      it "should work with uppercase strings" do
        @app.mime_type_for('PNG').should == 'image/png'
      end
      it "should work with a dot" do
        @app.mime_type_for('.png').should == 'image/png'
      end
      it "should return nil if not known" do
        @app.mime_type_for(:mark).should be_nil
      end
      it "should allow for configuring extra mime types" do
        @app.register_mime_type 'mark', 'application/mark'
        @app.mime_type_for(:mark).should == 'application/mark'
      end
      it "should override existing mime types when registered" do
        @app.register_mime_type :png, 'ping/pong'
        @app.mime_type_for(:png).should == 'ping/pong'
      end
      it "should have a per-app mime-type configuration" do
        other_app = Dragonfly[:other_app]
        @app.register_mime_type(:mark, 'first/one')
        other_app.register_mime_type(:mark, 'second/one')
        @app.mime_type_for(:mark).should == 'first/one'
        other_app.mime_type_for(:mark).should == 'second/one'
      end
    end
    
    describe "#resolve_mime_type" do
      before(:each) do
        @app = test_app
        @app.analyser.add :format do |temp_object|
          :png
        end
        @app.analyser.add :mime_type do |temp_object|
          'image/jpeg'
        end
        @app.encoder.add do |temp_object|
          'ENCODED DATA YO'
        end
      end

      it "should return the correct mime_type if the temp_object has a format" do
        temp_object = Dragonfly::TempObject.new("HIMATE", :format => :tiff, :name => 'test.pdf')
        @app.resolve_mime_type(temp_object).should == 'image/tiff'
      end

      it "should use the file extension if it has no format" do
        temp_object = Dragonfly::TempObject.new("HIMATE", :name => 'test.pdf')
        @app.resolve_mime_type(temp_object).should == 'application/pdf'
      end

      it "should not use the file extension if it's been switched off (fall back to mime_type analyser)" do
        @app.infer_mime_type_from_file_ext = false
        temp_object = Dragonfly::TempObject.new("HIMATE", :name => 'test.pdf')
        @app.resolve_mime_type(temp_object).should == 'image/jpeg'
      end

      it "should fall back to the mime_type analyser if the temp_object has no ext" do
        temp_object = Dragonfly::TempObject.new("HIMATE", :name => 'test')
        @app.resolve_mime_type(temp_object).should == 'image/jpeg'
      end

      describe "when the temp_object has no name" do

        before(:each) do
          @temp_object = Dragonfly::TempObject.new("HIMATE")
        end

        it "should fall back to the mime_type analyser" do
          @app.resolve_mime_type(@temp_object).should == 'image/jpeg'
        end

        it "should fall back to the format analyser if the mime_type analyser doesn't exist" do
          @app.analyser.functions.delete(:mime_type)
          @app.resolve_mime_type(@temp_object).should == 'image/png'
        end

        it "should fall back to the app's fallback mime_type if no mime_type/format analyser exists" do
          @app.analyser.functions.delete(:mime_type)
          @app.analyser.functions.delete(:format)
          @app.resolve_mime_type(@temp_object).should == 'application/octet-stream'
        end

      end

    end
    
  end

  describe "without path prefix or DOS protection" do
    before(:each) do
      @app = test_app
      @job = Dragonfly::Job.new(@app).fetch('some_uid')
      @app.datastore.stub!(:retrieve).with('some_uid').and_return "Hi there"
      @app.configure{|c| c.protect_from_dos_attacks = false }
    end
    it "should correctly respond with the job data" do
      response = request(@app, "/#{@job.serialize}")
      response.status.should == 200
      response.body.should == "Hi there"
    end
    it "should generate the correct url" do
      @app.url_for(@job).should == "/#{@job.serialize}"
    end
  end

  describe "url_path_prefix" do
    before(:each) do
      @app = test_app
      @job = Dragonfly::Job.new(@app)
    end
    it "should add the path prefix to the url if configured" do
      @app.url_path_prefix = '/media'
      @app.url_for(@job).should =~ %r{^/media/\w+$}
    end
    it "should add the path prefix to the url if passed in" do
      @app.url_for(@job, :path_prefix => '/eggs').should =~ %r{^/eggs/\w+$}
    end
    it "should favour the passed in one" do
      @app.url_path_prefix = '/media'
      @app.url_for(@job, :path_prefix => '/bacon').should =~ %r{^/bacon/\w+$}
    end
  end

  describe "url_host" do
    before(:each) do
      @app = test_app
      @job = Dragonfly::Job.new(@app)
    end
    it "should add the host to the url if configured" do
      @app.url_host = 'http://some.server:4000'
      @app.url_for(@job).should =~ %r{^http://some\.server:4000/\w+$}
    end
    it "should add the host to the url if passed in" do
      @app.url_for(@job, :host => 'https://bungle.com').should =~ %r{^https://bungle\.com/\w+$}
    end
    it "should favour the passed in one" do
      @app.url_host = 'http://some.server:4000'
      @app.url_for(@job, :host => 'https://smeedy').should =~ %r{^https://smeedy/\w+$}
    end
  end
  
  describe "Denial of Service protection" do
    before(:each) do
      @app = test_app
      @app.protect_from_dos_attacks = true
      @job = Dragonfly::Job.new(@app).fetch('some_uid')
    end
    it "should generate the correct url" do
      @app.url_for(@job).should == "/#{@job.serialize}?s=#{@job.sha}"
    end
  end

  describe "configuring with saved configurations" do
    before(:each) do
      @app = test_app
    end
    
    {
      :rmagick => Dragonfly::Config::RMagick,
      :r_magick => Dragonfly::Config::RMagick,
      :rails => Dragonfly::Config::Rails,
      :heroku => Dragonfly::Config::Heroku,
    }.each do |key, klass|
      it "should map #{key} to #{klass}" do
        klass.should_receive(:apply_configuration).with(@app)
        @app.configure_with(key)
      end
    end

    it "should description" do
      lambda {
        @app.configure_with(:eggs)
      }.should raise_error(ArgumentError)
    end
  end

  describe "#store" do
    before(:each) do
      @app = test_app
    end
    it "should allow just storing content" do
      @app.datastore.should_receive(:store).with(a_temp_object_with_data("HELLO"), {})
      @app.store("HELLO")
    end
    it "should allow storing using a TempObject" do
      temp_object = Dragonfly::TempObject.new("HELLO")
      @app.datastore.should_receive(:store).with(temp_object, {})
      @app.store(temp_object)
    end
    it "should allow storing with extra stuff" do
      @app.datastore.should_receive(:store).with(
        a_temp_object_with_data("HELLO", :meta => {:egg => :head}),
        {:option => :blarney}
      )
      @app.store("HELLO", :meta => {:egg => :head}, :option => :blarney)
    end
  end

end
