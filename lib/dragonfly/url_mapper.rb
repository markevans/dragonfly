module Dragonfly
  class UrlMapper
    
    # Exceptions
    class MissingParams < StandardError; end
    class BadUrlFormat < StandardError; end
    
    class Segment < Struct.new(:param, :seperator, :pattern, :required)
    
      def regexp_string
        @regexp_string ||= begin
          reg = "(#{Regexp.escape(seperator)}#{pattern}+?)"
          reg << '?' unless required
          reg
        end
      end
      
      def regexp
        @regexp ||= Regexp.new(regexp_string)
      end
    
    end
    
    def initialize(url_format, segment_specs={})
      @url_format = url_format
      raise BadUrlFormat, "bad url format #{url_format}" if url_format[/[\w_]:[\w_]/]
      init_segments(segment_specs)
      init_url_regexp
    end

    attr_reader :url_format, :url_regexp, :segments
    
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
    
    def required_params
      @required_params ||= segments.select{|s| s.required }.map{|s| s.param }
    end
    
    def url_for(params)
      params = params.dup
      url = url_format.dup
      segments.each do |seg|
        value = params[seg.param]
        raise MissingParams, "missing param #{seg.param.inspect}" if seg.required && !value
        value ? url.sub!(/:[\w_]+/, value) : url.sub!(/.:[\w_]+/, '')
        params.delete(seg.param)
      end
      url << "?#{Rack::Utils.build_query(params)}" if params.any?
      url
    end
    
    private
    
    # specs should look like e.g.
    # {
    #   :job => {:pattern => /\w/, :required => true},
    #   ...
    # }
    def init_segments(specs)
      @segments = []
      url_format.scan(/([^\w_]):([\w_]+)/).each do |seperator, param|
        spec = specs[param.to_sym] || {}
        segments << Segment.new(
          param,
          seperator,
          spec[:pattern] || '[\w_]',
          spec[:required]
        )
      end
    end
    
    def init_url_regexp
      regexp_string = url_format.gsub(/[^\w_]:([\w_]+)/).with_index do |_, i|
        segments[i].regexp_string
      end
      @url_regexp = Regexp.new('^' + regexp_string + '$')
    end
    
  end
end
