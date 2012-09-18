require 'spec_helper'

describe "a configured imagemagick app" do

  let(:app){ test_app }

  describe "convert command path" do

    it "should default to 'convert'" do
      app.configure do
        use :imagemagick
      end
      app.plugins[:imagemagick].processor.command_line.convert_command.should == 'convert'
    end

    it "should allow configuring" do
      app.configure do
        use :imagemagick do
          convert_command '/usr/eggs'
        end
      end
      app.plugins[:imagemagick].processor.command_line.convert_command.should == '/usr/eggs'
    end

  end

  describe "convert" do
    let(:app){ test_app.configure_with(:imagemagick) }
    let(:image){ app.fetch_file(SAMPLES_DIR.join('beach.png')) }
    
    it "sanity check with format" do
      thumb = image.convert('-resize 1x1!', :jpg)
      thumb.url.should =~ /beach\.jpg/
      thumb.width.should == 1
      thumb.analyse(:format).should == :jpeg
      thumb.meta[:format].should == :jpg
    end

    it "sanity check without format" do
      thumb = image.convert('-resize 1x1!')
      thumb.url.should =~ /beach\.png/
      thumb.width.should == 1
      thumb.analyse(:format).should == :png
      thumb.meta[:format].should be_nil
    end
  end

end
