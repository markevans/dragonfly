module Dragonfly
  module Generation
    puts "WARNING: Dragonfly::Generation::ImageMagickGenerator is DEPRECATED and will soon be removed. Please use Dragonfly::ImageMagick::Generator instead."
    ImageMagickGenerator = ImageMagick::Generator
  end
end
