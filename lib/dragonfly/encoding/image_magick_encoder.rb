module Dragonfly
  module Encoding
    puts "WARNING: Dragonfly::Encoding::ImageMagickEncoder is DEPRECATED and will soon be removed. Please use Dragonfly::ImageMagick::Encoder instead."
    ImageMagickEncoder = ImageMagick::Encoder
  end
end
