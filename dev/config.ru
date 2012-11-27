require "rubygems"
require "bundler/setup"
$:.unshift(File.expand_path('../lib', __FILE__))
require 'dragonfly'
require 'rack/cache'

APP = Dragonfly[:images].configure_with(:imagemagick)

run APP
