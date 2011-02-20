module Dragonfly
  module Processing
    puts "WARNING: Dragonfly::Processing::ImageMagickProcessor is DEPRECATED and will soon be removed. Please use Dragonfly::ImageMagick::Processor instead."
    ImageMagickProcessor = ImageMagick::Processor
  end
end
