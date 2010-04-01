require 'rack'

module Dragonfly
  class Route
    
    # Exceptions
    class NotFound < RuntimeError; end
    
    include Rack::Utils
  
    def initialize(path_spec, query_spec)
      @path_spec, @query_spec = path_spec, query_spec
    end

    def parse_url(path, query_string)
      attrs_from_path  = parse_path(path)
      attrs_from_query = parse_query_string(query_string)
      attrs_from_path.merge(attrs_from_query)
    end
  
    def to_url(params)
      # substitute named portions of the path spec with the value from params
      path = %w(uid job).inject(@path_spec) do |path, meth|
        path.sub( /\(\?<#{meth}>[^\(\)]+\)/, escape(params.send(meth) || '') )
      end
      query = @query_spec.inject({}) do |query, (k, meth)|
        value = params.send(meth)
        query[k] = value if value
        query
      end
      query_string = build_query(query)
      [path, query_string].reject{|i| i.blank? }.join('?')
    end
  
    private
    def regexp
      @regexp ||= Regexp.new(@path_spec)
    end
  
    def parse_path(path)
      match_data = regexp.match(path)
      raise NotFound, "path '#{path}' not found" unless match_data
      Hash[[match_data.names, match_data.captures].transpose]
    end
  
    def parse_query_string(query_string)
      query = parse_query(query_string)
      attrs_from_query = @query_spec.inject({}) do |attrs, (k, v)|
        attrs[v.to_s] = query[k.to_s]
        attrs
      end
    end
  end
end
