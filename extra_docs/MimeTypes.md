Mime Types
==========

Responses from the Dragonfly app have the HTTP 'Content-Type' header set.

Suppose we request the url '/media/some_uid.jpg'.
The mime-type is looked for in the following order (and the first found is used):

1. The app's registered mime-types
2. Analyse the content using the analyser's 'mime_type' method (if exists)
3. Use the fallback mime-type (default 'application/octet-stream')

Registered mime-types
---------------------
Registered mime-types default to the list given by Rack (see {http://rack.rubyforge.org/doc/Rack/Mime.html#MIME_TYPES Rack mime-types}).

To register a mime-type for the format 'egg', you can do the following:

    Dragonfly[:my_app].register_mime_type(:egg, 'fried/egg')

You can also do this inside a configuration block.

Mime-type analysis
------------------
The {Dragonfly::Analysis::FileCommandAnalyser FileCommandAnalyser} has a `mime_type` method which will return the
mime-type of any given content.

If this, or any other analyser that has the `mime_type` method, is registered, then this is used when no mime-type
is found in the registered list.

The FileCommandAnalyser is registered by default when you use the preconfigured 'dragonfly/rails/images' file.

Fallback mime-type
------------------
By default this is 'application/octet-stream', but it can be changed using the configuration method on the app

    Dragonfly[:my_app].fallback_mime_type = 'meaty/beef'

This can also be done inside a configuration block.
