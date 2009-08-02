module Imagetastic
  module UrlHandler
    
    include Rack::Utils

    def query_to_params(query_string)
      parse_query(query_string).inject({}) do |memo, k_and_v|
        k,v = k_and_v
        if k =~ /^(.+)\[(.+)\]$/
          key, key_2 = $1, $2
          memo[key] ||= {}
          memo[key][key_2] = v
        else
          memo[k] = v
        end
        memo
      end
    end
    
  end
end