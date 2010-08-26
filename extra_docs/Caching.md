Caching
=======

Processing and encoding can be an expensive operation. The first time we visit the url,
the image is processed, and there might be a short delay and getting the response.

However, dragonfly apps send `Cache-Control` and `ETag` headers in the response, so we can easily put a caching
proxy like {http://varnish.projects.linpro.no Varnish}, {http://www.squid-cache.org Squid},
{http://tomayko.com/src/rack-cache/ Rack::Cache}, etc. in front of the app, so that subsequent requests are served
super-quickly straight out of the cache.

The file 'dragonfly/rails/images' puts Rack::Cache in front of Dragonfly by default, but for better performance
you may wish to look into something like Varnish.

Given a dragonfly app

    app = Dragonfly[:images]

You can configure the 'Cache-Control' header with

    app.cache_duration = 3600*24*365*3  # time in seconds

For a well-written discussion of Cache-Control and ETag headers, see {http://tomayko.com/writings/things-caches-do}.
