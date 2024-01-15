module Dragonfly
  class DefaultUrlFetchFactory
    def create
      DefaultUrlFetch.new
    end
  end

  class DefaultUrlFetch

    def get(url)
      url = parse_url(url)

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if url.scheme == 'https'

      request = Net::HTTP::Get.new(url.request_uri)

      if url.user || url.password
        request.basic_auth(url.user, url.password)
      end

      http.request(request)
    end

    def get_following_redirects(url, redirect_limit=10)
      raise TooManyRedirects, "url #{url} redirected too many times" if redirect_limit == 0
      response = get(url)
      case response
        when Net::HTTPSuccess then response
        when Net::HTTPRedirection then
          get_following_redirects(redirect_url(url, response['location']), redirect_limit-1)
        else
          response.error!
      end
    rescue Net::HTTPExceptions => e
      raise ErrorResponse.new(e.response.code.to_i, e.response.body)
    end

    private

    def parse_url(url)
      URI.parse(url.to_s)
    rescue URI::InvalidURIError
      begin
        encoded_uri = Addressable::URI.parse(url).normalize.to_s
        URI.parse(encoded_uri)
      rescue Addressable::URI::InvalidURIError => e
        raise BadURI, e.message
      rescue URI::InvalidURIError => e
        raise BadURI, e.message
      end
    end

  end
end