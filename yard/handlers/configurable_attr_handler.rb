class ConfigurableAttrHandler < YARD::Handlers::Ruby::Legacy::Base
  handles /configurable_attr/

  def process
    owner[:configurable_attributes] ||= []
    owner[:configurable_attributes] << statement.tokens.to_s
  end
end
