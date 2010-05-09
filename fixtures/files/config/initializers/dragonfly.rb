# This is a hack to get the generated rails apps to use the version of dragonfly being worked on.
$:.unshift(File.expand_path(File.dirname(__FILE__)+'/../../../../../lib'))
require 'dragonfly/rails/images'

