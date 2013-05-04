this_dir = File.dirname(__FILE__)

YARD::Templates::Engine.register_template_path(this_dir + '/templates')
Dir[this_dir + '/handlers/*.rb'].each do |file|
  require File.expand_path(file)
end
YARD::Parser::SourceParser.parser_type = :ruby18

version = ENV['DRAGONFLY_VERSION']
DRAGONFLY_VERSION = if version
  puts "Setting the version in the docs to #{version}"
  version
else
  require "#{this_dir}/../lib/dragonfly/version"
  Dragonfly::VERSION
end
