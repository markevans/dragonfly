module Dragonfly
  
  # HashWithCssStyleKeys is solely for being able to access a hash
  # which has css-style keys (e.g. 'font-size') with the underscore
  # symbol version
  # @example
  #   opts = {'font-size' => '23px', :color => 'white'}
  #   opts = HashWithCssStyleKeys[opts]
  #   opts[:font_size]   # ===> '23px'
  #   opts[:color]       # ===> 'white'
  class HashWithCssStyleKeys < Hash
    def [](key)
      super || (
        str_key = key.to_s
        css_key = str_key.gsub('_','-')
        super(str_key) || super(css_key) || super(css_key.to_sym)
      )
    end
  end

end
