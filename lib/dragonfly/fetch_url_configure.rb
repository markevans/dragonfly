require 'dragonfly/fetch_url_configure/configuration'

module Dragonfly
  module FetchUrlConfigure

    class << self

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end
    end
  end
end
