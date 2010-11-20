require 'spec_helper'
require 'dragonfly/generation/shared_generator_spec'

describe Dragonfly::Generation::ImageMagickGenerator do

  before(:each) do
    @generator = Dragonfly::Generation::ImageMagickGenerator.new
  end

  it_should_behave_like 'image generator'

end
