require File.dirname(__FILE__) + '/lib/dragonfly'

APP = Dragonfly::App[:images]
APP.configure_with(Dragonfly::Config::RMagickImages)
APP.url_handler.protect_from_dos_attacks = false
