module Dragonfly
  module Analysis
    puts "WARNING: Dragonfly::Analysis::ImageMagickAnalyser is DEPRECATED and will soon be removed. Please use Dragonfly::ImageMagick::Analyser instead."
    ImageMagickAnalyser = ImageMagick::Analyser
  end
end
