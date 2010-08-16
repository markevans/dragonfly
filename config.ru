require 'rubygems'
require 'rack/cache'
require File.dirname(__FILE__) + '/lib/dragonfly'

APP = Dragonfly[:images].configure_with(:rmagick) do |c|
end

use Rack::Cache,
  :verbose     => true,
  :metastore   => 'file:/var/cache/rack/meta',
  :entitystore => 'file:/var/cache/rack/body'

run APP
