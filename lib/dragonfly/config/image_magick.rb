module Dragonfly
  module Config
    puts "WARNING: Dragonfly::Config::ImageMagick is DEPRECATED and will soon be removed. Please use Dragonfly::ImageMagick::Config instead."
    ImageMagick = Dragonfly::ImageMagick::Config
  end
end
