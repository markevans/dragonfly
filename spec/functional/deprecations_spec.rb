require 'spec_helper'

describe 'deprecations' do
  
  before(:each) do
    @app = test_app
  end
  
  describe "url_suffix" do
    it "should give an appropriate error" do
      @app.configure do |c|
        expect{
          c.url_suffix = 'darble'
        }.to raise_error(NoMethodError, /deprecated.*please use url_format/)
      end
    end
  end
  
  describe "url_path_prefix" do
    it "should give an appropriate error" do
      @app.configure do |c|
        expect{
          c.url_path_prefix = '/darble'
        }.to raise_error(NoMethodError, /deprecated.*please use url_format/)
      end
    end
  end
  
  describe "middleware" do
    it "should give an appropriate error" do
      app = Rack::Builder.new do
        use Dragonfly::Middleware, :images, '/media'
        run proc{[200, {}, []]}
      end
      expect{
        app.call({})
      }.to raise_error(ArgumentError, /deprecated/)
    end
  end
  
  describe "infer_mime_type_from_file_ext" do
    it "should give an appropriate error" do
      @app.configure do |c|
        expect{
          c.infer_mime_type_from_file_ext = false
        }.to raise_error(NoMethodError, /deprecated.*please use trust_file_extensions = false/)
      end
    end
  end
  
end
