class ConfigurableAttrHandler < YARD::Handlers::Ruby::Legacy::Base
  handles(/^\s*configurable_attr/)

  def process
    namespace[:configurable_attributes] ||= []
    
    attribute = token_to_object(statement.tokens[2])
    comments = statement.comments.join(' ') if statement.comments
    
    if statement.block
    # e.g. configurable_attr :datastore do FileDataStore.new end
      lazy_default_value = statement.block.to_s
    else
    # e.g. configurable_attr :fallback_mime_type, 'application/octet-stream'    
      default_value = token_to_object(statement.tokens[5..-1])
    end
    namespace[:configurable_attributes] << {
      :attribute => attribute,
      :default_value => default_value,
      :lazy_default_value => lazy_default_value,
      :comments => comments
    }
  end

  private

  def token_to_object(token)
    if token
      if token.is_a?(YARD::Parser::Ruby::Legacy::TokenList)
        eval(token.to_s)
      else # is a single token
        eval(token.text)
      end
    end
  end

end

