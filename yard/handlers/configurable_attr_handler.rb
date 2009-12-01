YARD::Templates::Engine.register_template_path(File.dirname(__FILE__) + '/../templates')
YARD::Parser::SourceParser.parser_type = :ruby18

class ConfigurableAttrHandler < YARD::Handlers::Ruby::Legacy::Base
  handles /configurable_attr/

  def process
    owner[:boogie] = statement.tokens
  end
end
