require File.dirname(__FILE__) + '/lib/dragonfly'

APP = Dragonfly::App[:images]
APP.configure_with(Dragonfly::Config::RMagickImages)
