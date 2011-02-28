module Dragonfly
  class UrlMapper
    
    # Exceptions
    class MissingParams < StandardError; end
    class BadUrlFormat < StandardError; end
    
    DEFAULT_SEGMENT_PATTERN = '[\w_]?'
    
    def initialize(url_format, segment_patterns={})
      @url_format = url_format
      @segment_patterns = segment_patterns
      generate_url_regexp
    end

    attr_reader :url_format, :url_regexp, :segment_patterns
    
    def params_for(url)
      path, query = url.split('?')
      if path and md = path.match(url_regexp)
        params = Rack::Utils.parse_query(query)
        params_in_url.each_with_index do |var, i|
          value = md[i+1][1..-1] if md[i+1]
          params[var] = value
        end
        params
      end
    end

    def params_in_url
      @params_in_url ||= url_format.scan(/\:[\w_]+/).map{|f| f.tr(':','') }
    end
    
    def url_for(params)
      params = params.dup
      url = url_format.dup
      params.each do |k, v|
        params.delete(k) if url.sub!(":#{k.to_s}", v)
      end
      url << "?#{Rack::Utils.build_query(params)}" if params.any?
      if url[':']
        raise MissingParams, "missing params #{url.scan(/\:[\w_]+/).join(', ')}"
      end
      url
    end
    
    private
    
    def generate_url_regexp
      raise BadUrlFormat, "bad url format #{url_format}" if url_format[/[\w_]:[\w_]/]
      regexp_string = url_format.gsub(/([^\w_]):([\w_]+)/) do
        pattern = segment_patterns[$2.to_sym] || DEFAULT_SEGMENT_PATTERN
        seperator = Regexp.escape($1)
        if pattern[-1..-1] == '?'
          "(#{seperator}#{pattern[0..-2]}+?)?"
        else
          "(#{seperator}#{pattern}+?)"
        end
      end
      @url_regexp = Regexp.new('^' + regexp_string + '$')
    end
    
  end
end
