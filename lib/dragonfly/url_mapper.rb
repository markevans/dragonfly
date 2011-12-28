module Dragonfly
  class UrlMapper
    
    # Exceptions
    class BadUrlFormat < StandardError; end
    
    class Segment < Struct.new(:param, :seperator, :pattern)
    
      def regexp_string
        @regexp_string ||= "(#{Regexp.escape(seperator)}#{pattern}+?)?"
      end
      # 
      # def regexp
      #   @regexp ||= Regexp.new(regexp_string)
      # end
    
    end
    
    def initialize(url_format, patterns={})
      @url_format = url_format
      raise BadUrlFormat, "bad url format #{url_format}" if url_format[/[\w_]:[\w_]/]
      init_segments(patterns)
      init_url_regexp
    end

    attr_reader :url_format, :url_regexp, :segments
    
    def params_for(path, query=nil)
      if path and md = path.match(url_regexp)
        params = Rack::Utils.parse_query(query)
        params_in_url.each_with_index do |var, i|
          value = md[i+1][1..-1] if md[i+1]
          params[var] = value && URI.unescape(value)
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
      segments.each do |seg|
        value = params[seg.param]
        value ? url.sub!(/:[\w_]+/, URI.escape(value.to_s)) : url.sub!(/.:[\w_]+/, '')
        params.delete(seg.param)
      end
      url << "?#{Rack::Utils.build_query(params)}" if params.any?
      url
    end
    
    private
    
    def init_segments(patterns)
      @segments = []
      url_format.scan(/([^\w_]):([\w_]+)/).each do |seperator, param|
        segments << Segment.new(
          param,
          seperator,
          patterns[param.to_sym] || '[^\/\-\.]'
        )
      end
    end
    
    def init_url_regexp
      i = -1
      regexp_string = url_format.gsub(/[^\w_]:[\w_]+/) do
        i += 1
        segments[i].regexp_string
      end
      @url_regexp = Regexp.new('^' + regexp_string + '$')
    end
    
  end
end
