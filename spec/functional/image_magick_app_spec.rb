require 'spec_helper'

describe "a configured imagemagick app" do
  
  let(:app){ test_app }
  
  describe "convert command path" do
    
    it "should default to 'convert'" do
      app.configure do
        use :imagemagick
      end
      processor = app.processor.get_registered(Dragonfly::ImageMagick::Processor)
      processor.command_line.convert_command.should == 'convert'
    end
    
    it "should allow configuring" do
      app.configure do
        use :imagemagick do
          convert_command '/usr/eggs'
        end
      end
      processor = app.processor.get_registered(Dragonfly::ImageMagick::Processor)
      processor.command_line.convert_command.should == '/usr/eggs'
    end
    
  end
  
end
