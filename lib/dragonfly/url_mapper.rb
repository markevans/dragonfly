module Dragonfly
  class UrlMapper
    
    # Exceptions
    class MissingParams < StandardError; end
    
    PARAM_FORMAT = /\:[\w_]+/
    
    def initialize(url_format)
      self.url_format = url_format
      self.url_regexp = Regexp.new('^' + url_format.gsub(PARAM_FORMAT, '([\w_]+)') + '$')
      self.url_regexp_groups = url_format.scan(PARAM_FORMAT).map{|f| f.tr(':','') } # Unfortunately we don't have named groups in Ruby 1.8
    end

    attr_accessor :url_format
    
    def url_for(params)
      params = params.dup
      url = url_format.dup
      params.each do |k, v|
        params.delete(k) if url.sub!(":#{k.to_s}", v)
      end
      url << "?#{Rack::Utils.build_query(params)}" if params.any?
      if url[':']
        raise MissingParams, "missing params #{url.scan(PARAM_FORMAT).join(', ')}"
      end
      url
    end
    
    def params_for(url)
      path, query = url.split('?')
      if path and md = path.match(url_regexp)
        params = Rack::Utils.parse_query(query)
        url_regexp_groups.each_with_index do |var, i|
          params[var] = md[i+1]
        end
        params
      end
    end
    
    private
    
    attr_accessor :url_regexp, :url_regexp_groups
    
  end
end
