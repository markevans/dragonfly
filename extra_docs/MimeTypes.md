Mime Types
==========

Responses from the Dragonfly app have the HTTP 'Content-Type' header set.

This is decided by the first found from:

1. The requested format (e.g. when encode is specifically called)
2. The original file extension (you can configure it to ignore this if you wish)
3. Analyse the content using the analyser's 'format' method (if exists)
4. Analyse the content using the analyser's 'mime_type' method (if exists)
5. Use the fallback mime-type (default 'application/octet-stream')

Note that 'format' means 'jpg', 'png', etc. whereas mime-type would be 'image/jpeg', image/png', etc.
Formats are mapped to mime-types using the app's registered list of mime-types.

Registered mime-types
---------------------
Registered mime-types default to the list given by Rack (see {http://rack.rubyforge.org/doc/Rack/Mime.html#MIME_TYPES Rack mime-types}).

To register a mime-type for the format 'egg':

    Dragonfly[:my_app].register_mime_type(:egg, 'fried/egg')

You can also do this inside a configuration block.

Analysers
---------
The {Dragonfly::Analysis::FileCommandAnalyser FileCommandAnalyser} has a `mime_type` method and the
{Dragonfly::ImageMagick::Analyser ImageMagick Analyser} has a `format` method.

These are both registered by default when you use the preconfigured 'dragonfly/rails/images' file.

Fallback mime-type
------------------
By default this is 'application/octet-stream', but it can be changed using

    Dragonfly[:my_app].fallback_mime_type = 'meaty/beef'

This can also be done inside a configuration block.
