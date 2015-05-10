require 'spec_helper'

describe "a configured imagemagick app" do

  let(:app){ test_app.configure_with(:imagemagick) }
  let(:image){ app.fetch_file(SAMPLES_DIR.join('beach.png')) }

  describe "env variables" do
    let(:app){ test_app }

    it "allows setting the convert command" do
      app.configure do
        plugin :imagemagick, :convert_command => '/bin/convert'
      end
      app.env[:convert_command].should == '/bin/convert'
    end

    it "allows setting the identify command" do
      app.configure do
        plugin :imagemagick, :identify_command => '/bin/identify'
      end
      app.env[:identify_command].should == '/bin/identify'
    end
  end

  describe "analysers" do
    it "should return the width" do
      image.width.should == 280
    end

    it "should return the height" do
      image.height.should == 355
    end

    it "should return the aspect ratio" do
      image.aspect_ratio.should == (280.0/355.0)
    end

    it "should say if it's portrait" do
      image.portrait?.should be_truthy
      image.portrait.should be_truthy # for using with magic attributes
    end

    it "should say if it's landscape" do
      image.landscape?.should be_falsey
      image.landscape.should be_falsey # for using with magic attributes
    end

    it "should return the format" do
      image.format.should == "png"
    end

    it "should say if it's an image" do
      image.image?.should be_truthy
      image.image.should be_truthy # for using with magic attributes
    end

    it "should say if it's not an image" do
      app.create("blah").image?.should be_falsey
    end

    it "should return false for pdfs" do
      image.encode('pdf').image?.should be_falsey
    end
  end

  describe "processors that change the url" do
    before do
      app.configure{ url_format '/:name' }
    end

    describe "convert" do
      it "sanity check with format" do
        thumb = image.convert('-resize 1x1!', 'format' => 'jpg')
        thumb.url.should =~ /^\/beach\.jpg\?.*job=\w+/
        thumb.width.should == 1
        thumb.format.should == 'jpeg'
        thumb.meta['format'].should == 'jpg'
      end

      it "sanity check without format" do
        thumb = image.convert('-resize 1x1!')
        thumb.url.should =~ /^\/beach\.png\?.*job=\w+/
        thumb.width.should == 1
        thumb.format.should == 'png'
        thumb.meta['format'].should be_nil
      end
    end

    describe "encode" do
      it "sanity check" do
        thumb = image.encode('jpg')
        thumb.url.should =~ /^\/beach\.jpg\?.*job=\w+/
        thumb.format.should == 'jpeg'
        thumb.meta['format'].should == 'jpg'
      end
    end
  end

  describe "other processors" do
    describe "encode" do
      it "should encode the image to the correct format" do
        image.encode!('gif')
        image.format.should == 'gif'
      end

      it "should allow for extra args" do
        image.encode!('jpg', '-quality 1')
        image.format.should == 'jpeg'
        image.size.should < 2000
      end
    end

    describe "rotate" do
      it "should rotate by 90 degrees" do
        image.rotate!(90)
        image.width.should == 355
        image.height.should == 280
      end
    end

  end

  describe "identify" do
    it "gives the output of the command line" do
      image.identify.should =~ /280/
      image.identify("-format %h").chomp.should == "355"
    end
  end

end
