require 'spec_helper'

describe "a configured imagemagick app" do
  
  before(:each) do
    @app = test_app.configure_with(:imagemagick)
  end
  
  describe "convert command path" do
    before(:each) do
      @processor = @app.processor.get_registered(Dragonfly::ImageMagick::Processor)
    end
    
    it "should default to 'convert'" do
      @processor.convert_command.should == 'convert'
    end
    
    it "should change when configured through the app" do
      @app.configure do |c|
        c.convert_command = '/usr/eggs'
      end
      @processor.convert_command.should == '/usr/eggs'
    end
    
  end
  
end