require 'spec_helper'

describe "a configured imagemagick app" do

  let(:app){ test_app }

  describe "convert command path" do

    it "should default to 'convert'" do
      app.configure do
        use :imagemagick
      end
      app.processor.get(:convert).command_line.convert_command.should == 'convert'
      app.processor.get(:thumb).command_line.convert_command.should == 'convert'
    end

    it "should allow configuring" do
      app.configure do
        use :imagemagick do
          convert_command '/usr/eggs/convert'
        end
      end
      app.processor.get(:convert).command_line.convert_command.should == '/usr/eggs/convert'
      app.processor.get(:thumb).command_line.convert_command.should == '/usr/eggs/convert'
    end

  end

  describe "processors that change the url" do
    let(:app){ test_app.configure_with(:imagemagick).configure{ url_format '/:name' } }
    let(:image){ app.fetch_file(SAMPLES_DIR.join('beach.png')) }

    describe "convert" do
      it "sanity check with format" do
        thumb = image.convert('-resize 1x1!', :jpg)
        thumb.url.should =~ /^\/beach\.jpg\?job=\w+/
        thumb.width.should == 1
        thumb.format.should == :jpeg
        thumb.meta[:format].should == :jpg
      end

      it "sanity check without format" do
        thumb = image.convert('-resize 1x1!')
        thumb.url.should =~ /^\/beach\.png\?job=\w+/
        thumb.width.should == 1
        thumb.format.should == :png
        thumb.meta[:format].should be_nil
      end
    end

    describe "encode" do
      it "sanity check" do
        thumb = image.encode(:jpg)
        thumb.url.should =~ /^\/beach\.jpg\?job=\w+/
        thumb.format.should == :jpeg
        thumb.meta[:format].should == :jpg
      end
    end
  end

  describe "other processors" do
    let(:app){ test_app.configure_with(:imagemagick) }
    let(:image){ app.fetch_file(SAMPLES_DIR.join('beach.png')) }

    describe "auto-orient" do
      it "should rotate an image according to exif information" do
        image = app.fetch_file(SAMPLES_DIR.join('beach.jpg'))
        image.width.should == 355
        image.height.should == 280
        image.auto_orient!
        image.width.should == 280
        image.height.should == 355
      end
    end

    describe "flip" do
      it "should flip the image, leaving the same dimensions" do
        image.flip!
        image.width.should == 280
        image.height.should == 355
      end
    end

    describe "flop" do
      it "should flop the image, leaving the same dimensions" do
        image.flop!
        image.width.should == 280
        image.height.should == 355
      end
    end

    describe "encode" do
      it "should encode the image to the correct format" do
        image.encode!(:gif)
        image.format.should == :gif
      end

      it "should allow for extra args" do
        image.encode!(:jpg, '-quality 1')
        image.format.should == :jpg
        image.size.should == 1445
      end
    end

    describe "rotate" do
      it "should rotate by 90 degrees" do
        image.rotate!(90)
        image.width.should == 355
        image.height.should == 280
      end

      it "should not rotate given a larger height and the '>' qualifier" do
        image.rotate!(90, :qualifier => '>')
        image.width.should == 280
        image.height.should == 355
      end

      it "should rotate given a larger height and the '<' qualifier" do
        image.rotate!(90, :qualifier => '<')
        image.width.should == 355
        image.height.should == 280
      end
    end

    describe "strip" do
      it "should strip exif data" do
        jpg = app.fetch_file(SAMPLES_DIR.join('taj.jpg'))
        image = jpg.strip
        image.width.should == 300
        image.height.should == 300
        image.size.should < jpg.size
      end
    end

  end

end
