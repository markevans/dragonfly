# Allow debugging
require 'rubygems'
require 'ruby-debug'

YARD::Templates::Engine.register_template_path(File.dirname(__FILE__) + '/templates')
Dir[File.dirname(__FILE__) + '/handlers/*.rb'].each do |file|
  require File.expand_path(file)
end
YARD::Parser::SourceParser.parser_type = :ruby18
