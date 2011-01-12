require "rubygems"
require "bundler/setup"
$:.unshift(File.expand_path('../lib', __FILE__))
require 'dragonfly'
require 'rack/cache'

APP = Dragonfly[:images].configure_with(:imagemagick)

use Rack::Cache,
  :verbose     => true,
  :metastore   => 'file:/var/cache/rack/meta',
  :entitystore => 'file:/var/cache/rack/body'

run APP
