require 'dragonfly/default_url_fetch'

module Dragonfly
  module FetchUrlConfigure

    class Configuration
      attr_reader :url_fetch_factory

      def initialize
        @url_fetch_factory = Dragonfly::DefaultUrlFetchFactory.new
      end

      def url_fetch_factory=(factory)
        @url_fetch_factory = factory
      end
    end
  end

end