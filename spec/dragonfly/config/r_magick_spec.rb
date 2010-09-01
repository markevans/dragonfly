require File.dirname(__FILE__) + '/../../spec_helper'

describe Dragonfly::Config::RMagick do

  before(:each) do
    @app = test_app
  end

  it "should configure all to use the filesystem by default" do
    @app.configure_with(Dragonfly::Config::RMagick)
    @app.analyser.get_registered(Dragonfly::Analysis::RMagickAnalyser).use_filesystem.should be_true
    @app.processor.get_registered(Dragonfly::Processing::RMagickProcessor).use_filesystem.should be_true
    @app.encoder.get_registered(Dragonfly::Encoding::RMagickEncoder).use_filesystem.should be_true
    @app.generator.get_registered(Dragonfly::Generation::RMagickGenerator).use_filesystem.should be_true
  end

  it "should configure all not to use the filesystem if requested" do
    @app.configure_with(Dragonfly::Config::RMagick, :use_filesystem => false)
    @app.analyser.get_registered(Dragonfly::Analysis::RMagickAnalyser).use_filesystem.should be_false
    @app.processor.get_registered(Dragonfly::Processing::RMagickProcessor).use_filesystem.should be_false
    @app.encoder.get_registered(Dragonfly::Encoding::RMagickEncoder).use_filesystem.should be_false
    @app.generator.get_registered(Dragonfly::Generation::RMagickGenerator).use_filesystem.should be_false
  end

end
