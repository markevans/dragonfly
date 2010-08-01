require File.dirname(__FILE__) + '/lib/dragonfly'

APP = Dragonfly[:images]
APP.configure_with(Dragonfly::Config::RMagick)
