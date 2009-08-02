module Imagetastic
  module UrlHandler
    
    # Exceptions
    class UrlHandler::BadParams < RuntimeError; end
    
    include Rack::Utils

    VALID_PARAM_KEYS = %w{m opts sha}

    def query_to_params(query_string)
      if query_string && !query_string.empty?
        parse_query(query_string).inject({}) do |memo, k_and_v|
          k,v = k_and_v
          if k =~ /^(.+)\[(.+)\]$/
            k, k_2 = $1, $2
            memo[k] ||= {}
            memo[k][k_2] = v
          else
            memo[k] = v
          end
          raise BadParams, "'#{k}' is not a valid parameter" unless VALID_PARAM_KEYS.include?(k)
          memo
        end
      end
    end
    
  end
end