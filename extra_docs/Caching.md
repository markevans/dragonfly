
Caching
-------
Processing and encoding can be an expensive operation. The first time we visit the url,
the image is processed, and there might be a short delay and getting the response.

However, dragonfly apps send `Cache-Control` and `ETag` headers in the response, so we can easily put a caching
proxy like {http://varnish.projects.linpro.no Varnish}, {http://www.squid-cache.org Squid},
{http://tomayko.com/src/rack-cache/ Rack::Cache}, etc. in front of the app.

In the example above, we've put the middleware {http://tomayko.com/src/rack-cache/ Rack::Cache} in front of the app.
So although the first time we access the url the content is processed, every time after that it is received from the
cache, and is served super quick!
