require File.dirname(__FILE__) + '/lib/dragonfly'

include Dragonfly

APP = Dragonfly::App[:images]
APP.configure_with(StandardConfiguration)
APP.configure_with(RMagickConfiguration)
APP.url_handler.protect_from_dos_attacks = false
