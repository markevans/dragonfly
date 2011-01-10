unless ENV['IGNORE_RMAGICK']

  require 'spec_helper'
  require 'dragonfly/generation/shared_generator_spec'

  describe Dragonfly::Generation::RMagickGenerator do

    before(:each) do
      @generator = Dragonfly::Generation::RMagickGenerator.new
    end

    describe "when using the filesystem" do
      before(:each) do
        @generator.use_filesystem = true
      end
      it_should_behave_like 'image generator'
    end
  
    describe "when not using the filesystem" do
      before(:each) do
        @generator.use_filesystem = false
      end
      it_should_behave_like 'image generator'
    end
  
  end

end