require 'base64'

module Dragonfly
  module Serializer
    
    def b64_encode(string)
      Base64.encode64(string).strip.sub(/=+$/,'')
    end
    
    def b64_decode(string)
      padding_length = string.length % 4
      Base64.decode64(string + '=' * padding_length)
    end
    
  end
end
