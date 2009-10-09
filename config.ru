require File.dirname(__FILE__) + '/config'
require 'rubygems'
require 'rack/cache'

use Rack::Cache,
  :verbose     => true,
  :metastore   => 'file:/var/cache/rack/meta',
  :entitystore => 'file:/var/cache/rack/body'

run APP
