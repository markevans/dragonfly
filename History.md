1.1.3 (2017-06-02)
===================
Fixes
-----
- Make sure imagemagick convert processor updates mime_type correctly when format is changed

1.1.2 (2017-05-06)
===================
Fixes
-----
- Allow relative redirect urls in `fetch_url` (zorec)
- Fixed Forwardable deprecation warnings (neodude)
- Fixed incorrect detection of empty directories in ruby 2.4 (yuszuv)
- Store content type in meta if it's available so we don't lose information (Lukas Svoboda)

1.1.1 (2016-10-26)
===================
Features
--------
- Added delegate option for imagemagick (Will Fisher)

Fixes
-----
- Use `Base64.urlsafe_encode64` (Jan Raasch)
  Note that this changes b64 encodings from '/' to `'_'` and '+' to '-' in URLs, which will change a very
  small number of generated URLs (but shouldn't be enough to cause big recaching problems)
  URLs are encoded now according to the URL safe base64 specification in RFC 4648.
  Old URLs are still recognized so won't break.


1.1.0 (2016-10-24)
===================
Fixes
-----
- Fetch a URL with basic auth if it's present in the URI (Ben Pickles)
- Fix rack version problem for older rubies (rack 2.0 only works for ruby &gt;= 2.2.2)
- Updated deprecated syntax in tests for WebMock, RSpec

Changes
--------
- Dropped official support for Ruby &lt;= 1.9.2 and Rubinius

1.0.12 (2015-09-16)
===================
Features
--------
- Made thumb processor args for a specific geometry publicly accesible

1.0.11 (2015-09-04)
===================
Fixes
-----
- Make sure tempfiles are created with paths matching the meta name

1.0.10 (2015-05-14)
===================
Features
--------
- Allow method signified by symbol in storage_options to take an attachment object
- Allow passing in "input_args" to convert processor
Fixes
-----
- correct Rack version

1.0.9 (2015-04-29)
===================
Fixes
--------
- Remove sha parameter being echoed back on error for better security

1.0.8 (2015-04-23)
===================
Fixes
--------
- Job#close re-added, so that tempfiles are immediately removed after each request
- Specs passing for 1.8.7, 1.9.2 (i18n gem version specified)

1.0.7 (2014-08-26)
===================
Changes
--------
- Job#sha uses better algorithm
- renamed `protect_from_dos_attacks` -> `verify_urls` and turn on by default

1.0.6 (2014-08-22)
===================
Features
--------
- env can be accessed by routed endpoint blocks

Fixes
-----
- analyser cache doesn't get stored in meta for a given piece of meta - can mess with stringifying analyser return values
- removed default secret, forcing user to specify one explicitly
- deal with "[" character problems in urls https://github.com/markevans/dragonfly/pull/337

1.0.5 (2014-05-15)
===================
Fixes
-----
- fetch_url wasn't correctly getting https endpoints on Ruby approx < 2

1.0.4 (2014-04-11)
===================
Fixes
-----
- fetch_url is more forgiving - assume escaped, if not escape

1.0.3 (2014-01-28)
===================
Fixes
-----
- changing meta on a job (e.g. `fetch('blah').encode('jpg')`) was interfering with meta on its parent job (e.g. `fetch('blah')`)

1.0.2 (2013-12-20)
===================
Fixes
-----
- more secure generation of secret in rails generator
- ensure popen3 doesn't hang

1.0.1 (2013-11-28)
===================
Changes
-------
- FileDataStore doesn't use hours_minutes_seconds in its path - it uses a random string instead (12_15_59_saf4fs_file.png -> sdf4c2G_file.png)

Features
--------
- model attribute `xxx_changed?` method (useful e.g. in validations)

Fixes
-----
- proper support for Ruby 1.8.7 and JRuby (version 1.7.8)
- routed endpoints can deal with returned `Attachment` objects (rather than returned `Job` objects) and return 404 if the endpoint proc returns nil
- default Content-Disposition header doesn't url-encode filename unless the request is from IE
- `fetch_url` deals with urls that redirect to https (previously was blowing up)

1.0.0 (2013-11-24)
===================
Changes
-------
- configuration
  - `Dragonfly[:images]` -> `Dragonfly.app` and `Dragonfly.app(:named_app)`
  - configuration block DSL overhaul
  - Rails is set up using a generator, not by requiring the file "dragonfly/rails/images"
  - Rack::Cache is not inserted by Dragonfly - this is up to the user
- data store spec
  - `store`/`retrieve` -> `read`/`write`
  - `write` takes a `Content`, not a `TempObject` (though the interface is much the same)
  - return nil on `read` to signify not found instead of raising
- S3, Couch and Mongo data stores extracted into separate gems
- models
  - easier and simpler to include in custom models using `Dragonfly::Model`
  - `image_accessor`, `asset_accessor`, `xxx_accessor`, etc. -> single `dragonfly_accessor`
  - user needs to extend `Dragonfly::Model::Validations` manually to use dragonfly validations
- Custom processors, datastores, generators and analysers are made easier by `Content` object which has convenience methods
- Removed "encoders" - these are covered by processors now
- Removed "job" shortcuts - they are not needed as processors can invoke other processors
- No "smart" determination of mime-type - just use file extension (anything more than that can be done by the user)
- metadata is required to be serializable to/from JSON
- removed `allow_fetch_file` and `allow_fetch_url` in favour of more fine-control with `fetch_file_whitelist` and `fetch_url_whitelist`
- switch off dealing with legacy urls by default
- proper requires throughout the code instead of autoloading
- simple 500 response for unknown errors

Features
--------
- model attachment default (by specifying a path to a e.g. a default image)
- `convert` and `thumb` processors take a `'frame'` option
- `thumb` takes a `'format'` option
- `fetch_file` and `model.attachment_url=` accept a data uri string
- `Attachment#xxx_stored`, e.g. `my_model.my_attachment_stored?` (`my_attachment` here being the attachment name)
- `define` for creating custom methods on `Job`/`Attachment` objects
- `url_path_prefix` for when mounted in Rack with a "SCRIPT_NAME"
- when customizing response headers, ability to remove headers by setting to `nil`
- better logging
  - for each response
  - for shell commands

Fixes
-----
- inserting CookieMonster doesn't depend on existence of `ActionDispatch::Cookies`
- `image?` returns false for pdfs
- `fetch_url` raises more useful `ErrorResponse` on error
- shell commands don't print warnings to stderr
- ability to assign attachment/job from other app

0.9.15 (2013-05-04)
===================
Features
--------
- Allow turning off support of legacy urls

Fixes
-----
- More conservative URL escaping - back to Rack::Utils.escape_path
- Don't check for malicious strings when deserializing from datastores (they're to be trusted)

0.9.14 (2013-02-13)
===================
Features
--------
- Attachment#b64_data

Fixes
-----
- Fix '+' character being converted to ' ' (revert to URI.escape instead of Rack::Utils.escape)
- Support old-style deprecated urls (with a check for malicious ones)
- Handle case where uid is an empty string

0.9.13 (2013-01-30)
===================
Changes
-------
- URLS are encoded/decoded with JSON, not with Marshal

0.9.12 (2012-04-08)
===================
Features
-------
- Allow using a mongo replica set with mongo datastore

Fixes
-----
- `define_macro_on_include` was giving a stack error with multiple accessors on same app

0.9.11 (2012-03-12)
===================
Features
-------
- Allow the S3 base URL to be customised with `url_host` (or per-request)
- Added App#name (name as per `Dragonfly[:app_name]`)

Changes
-------
- Better inspect for App, Processor, Analyser, Encoder, Generator, Job, TempObject, RoutedEndpoint, JobEndpoint

Fixes
-----
- Rescue from Excon::Errors::Conflict which apparently gets raised sometimes (don't know why - see https://github.com/markevans/dragonfly/issues/167)
- Alias portrait and landscape without question marks, so magic_attributes can be used with them
- Fixed stack error when using `define_macro_on_include` twice
- Use fog's `sync_clock` to overcome potential S3 time skew problems
- Using :name in urls was causing problems when filenames had dashes in them

0.9.10 (2012-01-11)
===================
Fixes
-----
- FileDataStore was causing errors when the storage path was flat (not in a directory structure)

0.9.9 (2011-12-30)
==================
Features
--------
- Created tempfiles use the original file extension if known
- Added `:case_sensitive` option to `validates_property` for dealing with upper-case extensions and mime-types.
- Github Markup syntax on readme for code highlighting
- S3DataStore can use https for remote urls (either configurable or per-url)
- `to_file` can take `:mode` option for setting custom permissions
- `to_file` creates intermediate subdirs by default, can be turned off with `:mkdirs => false` option
- Added some more S3 regions

Changes
-------
- Datastores now use `temp_object.meta`, not the second arg passed in to `store`
- `meta`, `name`, etc. now lazily load the job on an attachment - previously you'd have to call `apply` to get the meta from the datastore
- When assigning an image via the activemodel extensions, mark that uid attribute will change
- `validates_property` uses Rails 3 validators
- Deprecated saved 'heroku' config, in favour of configuring S3 explicitly

Fixes
-----
- Model attachment urls are consistent now - the name is appended to the url (with format "/:job/:name") ONLY if it has the "name" magic attribute
- `identify` wasn't working properly for files with capital letter extensions
- S3 datastore sets content mime_type by default
- File extensions with numbers like JP2 weren't being processed/analysed properly
- Protect against object_ids being recycled and messing with analyser cache
- All url segments are correctly url-escaped now
- Fixed TempObject File.open mode
- S3DataStore was breaking on bucket_exists? when using AWS IAM
- Put CookieMonster before ActionDispatch::Cookies in rack middleware stack - that way Rack::Cache won't come between them and mess things up

0.9.8 (2011-09-08)
==================
Fixes
-----
- Regenerated gemspec again with ruby 1.8.7 - didn't seem to be fixed

0.9.7 (2011-09-08)
==================
Fixes
-----
- Regenerated gemspec to overcome annoying yaml issue (http://blog.rubygems.org/2011/08/31/shaving-the-yaml-yacc.html)

0.9.6 (2011-09-06)
==================
Features
--------
- Allow setting `content_type` when storing in Mongo GridFS

Changes
-------
- Tests use Rails 3.1

Fixes
-----
- Moved from fog's deprecated `get_object_url` to `get_object_https_url`
- Allow initializing a TempObject with Rack::Test::UploadedFile
- Tests working in Windows (except feature that uses FileCommandAnalyser)
- Better shell quoting

0.9.5 (2011-07-27)
==================
Features
--------
- Added reflection method `app.analyser_methods`

Fixes
-----
- Fixed `convert` and `identify` for files with spaces
- Fixed size validations for Rails 3.0.7

0.9.4 (2011-06-10)
==================
Fixes
-----
- Made use of Rack calling `close` on the response body to clean up tempfiles.
  The response body is now the job, which delegates `each` to the temp_object.

0.9.3 (2011-06-03)
==================
Fixes
-----
- TempObject#to_file sets file permissions 644 - copying wasn't previously guaranteeing this
- Added TempObject#close and closed?, which Rack uses to clean up tempfiles
- replaced '/' characters with '~' in base64 encoded urls (they were confusing url recognition)

0.9.2 (2011-05-19)
==================
Features
--------
- Added env['dragonfly.job'] for use in other Rack middlewares
- Added CookieMonster middleware for removing 'Set-Cookie' headers

Fixes
-----
- Remove 'Set-Cookie' header from any requests coming from a rails route

0.9.1 (2011-05-11)
==================
Features
--------
- Added reflection methods `app.processor_methods`, `app.generator_methods` and `app.job_methods`

Fixes
-----
- Improved performance of `resize_and_crop` method, using imagemagick built-in '^' operator
- Improved server security validations
- Deal with Excon::Errors::SocketError: EOFError errors which get thrown sometimes from S3 connection
- Allow files with '..' (but not '../') in the middle of their name in file data store

0.9.0 (2011-04-27)
==================
Features
--------
- Model accessors are configurable
  - added `after_assign` callback
  - added `after_unassign` callback
  - added `copy_to` for e.g. up-front thumbnailing
  - added `storage_opts` and `storage_xxx`
- Added model `remove_xxxxx` for using with checkboxes
- Added model `xxxx_url` for assigning content from a url
- Added job step `fetch_url`
- Added `retain!` and model `retained_xxxxx` for avoiding multiple uploads when validations fail
- Added `image?` to imagemagick analyser
- Added imagemagick `plain` generator
- Added `strip` to imagemagick processor
- Added CouchDataStore that uses a CouchDB as a data storage engine
- Added `before_serve` callback
- Allowed for configurable response headers
- Made url re-definable with `define_url`
- `validates_property` can take a proc for the message
- Saved configs can be registered now so they can be used with `configure_with(:symbol)`
- Configurable objects can fallback to a parent configuration, so e.g. the server can be configured through the parent app's configure block.
- Allowed initializing data by using a pathname
- `convert_command` and `identify_command` can be configured on a per-app basis
- Added `remote_url` and ability for datastores to form urls
  - Added for File, Couch and S3 datastores
- Models automatically copy magic attributes into meta
- S3DataStore configurable headers
- 'dragonfly/rails/images' slightly smarter and added `file_accessor` for more semantic use of non-image attachments
- Made dragonfly response configurable
- Mongo datastore can reuse an existing connection/db
- FileDataStore can be configured not to store meta (save on extra file)

Changes
-------
- Removed `url_path_prefix` and `url_suffix` in favour of `url_format`
  - Middleware doesn't need mount point argument now
- Removed support for rails 2.3
- Removed RMagick support (and extracted into a plugin)
- ImageMagick processors etc. moved into the ImageMagick namespace
- moved from aws/s3 -> fog for S3 support
- Renamed SimpleEndpoint -> Server
- moved name and meta into Job, simplified, and now they don't cause the job to be applied
- FileDataStore stores metadata in xxx.meta now, not xxx.extra
- removed Job methods `uid_basename`, `uid_extname`, `encoded_format` and `encoded_extname` as they are now unnecessary

Fixes
-----
- Performance tweaks regarding temp_objects model accessors and job objects

0.8.5 (2011-05-11)
==================
Fixes
-----
- Allow filenames that have '..' in them (but not '../') in the filedatastore
- Better security for server

0.8.4 (2011-04-27)
==================
Fixes
-----
- Security fix for file data store

0.8.2 (2011-01-11)
==================
Fixes
-----
- Renamed ActiveModel methods like 'attachments' to avoid name clashes
- Respond properly to HEAD, POST, PUT and DELETE requests
- Got it working with jRuby and Rubinius
- Made DOS protection SHA (and ETag) consistent

0.8.1 (2010-11-22)
==================
Fixes
-----
Removed runtime dependencies that Jeweler automatically takes from the Gemfile

0.8.0 (2010-11-21)
==================
Features
--------
- New ImageMagick generator, processor, encoder and analyser, which are now defaults
  (thanks to Henry Phan for work on this)

Fixes
-----
- Works with Rails 3.0.2 uploaded files (which has a changed API)


0.7.7 (2010-10-31)
==================
Features
--------
- Added username/password authentication to mongo data store

Fixes
-----
- Fixes for Windows, inc. tempfile binmode and closing files
- "IOError: closed stream" fix (hopefully!)


0.7.6 (2010-09-12)
==================
Features
--------
- Added methods for querying job steps, and Job#uid, Job#uid_basename, etc.
- Added Job#b64_data
- Added configurable url_suffix
- Added configurable content_disposition and content_filename
- Can pass extra GET params to url_for
- Can manually set uid on FileDataStore and S3DataStore
    (not yet documented because attachments have no way to pass it on yet)
- Model attachments store meta info about themselves

Changes
-------
- Configurable module doesn't implicitly call 'call' if attribute set as proc
- Refactored Endpoint module -> Response object

Fixes
-----
- Ruby 1.9.2-p0 was raising encoding errors due to Tempfiles not being in binmode


0.7.5 (2010-09-01)
==================
Changes
--------
- RMagick processor, encoder, analyser and generator all use the filesystem now
  They can be configured to use in-memory strings with the use_filesystem config option.
- Upgraded support from Rails 3.0.0.rc -> Rails.3.0.0

0.7.4 (2010-08-28)
==================
Features
--------
- Gave model accessors bang methods process! and encode!

0.7.3 (2010-08-27)
==================
Fixes
-----
- Seems as though inserting after Rails' Rack::Lock was worth it after all

0.7.2 (2010-08-27)
==================
Fixes
-----
- S3DataStore was breaking if previous data hadn't stored meta

0.7.1 (2010-08-26)
==================
Fixes
-----
- SimpleEndpoint was modifying env path_info so wasn't creating proper cache keys
- to_response accepts env, so can use if-not-modified, etc.

Features
--------
- Doc tweaks: Added mongo page, notes about Capistrano

Changes
-------
- ETags generated by hash of job.serialize - was getting a bit long

0.7.0 (2010-08-25)
==================

Features
--------
- Ability to chain processing, encoding
- Added Generators for arbitrary content generation
- 'fetch_file' method for easily getting local files
- ActiveModel support
- Mongoid support
- Better Sinatra, etc. support (using 'to_response')
- Data stores now store meta, name and format information too
- Added Mongo Data Store
- temp_objects maintain name, meta, etc. across processing, encoding, etc.
- added portrait? and landscape? to RMagick analyser
- Ability to add single custom processor/encoder/analyser/generator
- added flip and flop to RMagick processor
- ability to configure whether it trusts the file extension
- nice text response for root path
- ability to configure url host
- ability to override path_prefix/host when calling url
- routed endpoints
- simple endpoints
- more intelligent working out of Content-Type to send back

Fixes
-----
- proper use of ETags
- remove whitespace from file/s3 datastore uids
- dragonfly/rails/images url-encodes rack-cache config for windows users
- Ruby 1.9.2 support
- Better RMagick memory management using image.destroy!

Changes
-------
- Dragonfly::App[:images] -> Dragonfly[:images]
- Moved text/plasma generation into Generator
- Use of lazy 'Job' objects
- simplified shortcuts interface
- changed interface for attaching to ActiveRecord
- simplified saved configurations and allow referring to them as symbols
- Removed need for Base class for datastores, processors, analysers and encoders
- FileCommandAnalyser included in Rails config, not RMagick
- better use of logging module for sharing logs between classes
- mounting the app is down the middleware/elsewhere, not the app itself
- DOS protection off by default
- encoded urls
- got rid of unnecessary configurable sha_length



0.6.2 (2010-06-24)
==================
Features
-----
- Added ability for custom error messages in validations

0.6.1 (2010-05-16)
==================
Fixes
-----
- STI was breaking when the model had a mixin too

0.6.0 (2010-05-11)
==================

Features
--------
- Added 'scale factor' for text generation, which gives better quality font rendering for smaller fonts
- Configurable objects allow for passing args, and passing a block for extra config
- Added more 'saved configurations', for easier setting up on e.g. Heroku
- Added RMagickAnalyser#format
- Added greyscale to RMagickProcessor
- S3DataStore is configurable as to whether it uses the filesystem or not (to save a tempfile)

Fixes
-----
- Some specs refactoring, including making text processing specs less brittle
- RMagickEncoder::SUPPORTED_FORMATS was proving problematic - now we use a configurable list instead
- Got Rails 3 beta3 cucumber features working
- Added check to see if bucket already exists in S3DataStore - apparently this was problematic in EU

Changes
-------
- temp_object.tempfile now returns a closed tempfile, which temp_object.file returns an open file.
Can also pass a block to temp_object.file which closes the file automatically
- Processors/Analysers/Encoders know about app now so can log to app's log
- Imagemagick errors in RMagick processor/analyser/encoder now throw unable_to_handle and log a warning
- Removed Rails generators - better being more explicit with saved configurations which are more concise now

0.5.7 (2010-04-18)
==================

Fixes
--------
- Strip file command mime_type value because some versions of file command were appending a line-break

0.5.6 (2010-04-13)
==================

Fixes
--------
- Wasn't working properly with Single-Table Inheritance

0.5.5 (2010-04-13)
==================

Fixes
--------
- Rails 3 has changed 'metaclass' -> 'singleton_class' so adapt accordingly

0.5.4 (2010-04-12)
==================

Features
--------
- Allow setting the uid manually

Fixes
-----
- Assigning an accessor to nil wasn't working properly


0.5.3 (2010-03-27)
==================

Fixes
-----
- Assigning an accessor to nil wasn't working properly


0.5.2 (2010-03-04)
==================

Features
--------
- Added 'registered mime-types'
- Enhanced docs

Fixes
-----
- RMagickEncoder only encodes if not already in that format


0.5.1 (2010-02-20)
==================

Fixes
-----
- Fixed 'broken pipe' errors in FileCommandAnalyser due to outputting loads of stuff to the command line stdin

0.5.0 (2010-02-20)
==================

Added support
-------------
- support for Rails 3


0.4.4 (2010-02-16)
==================

Better late than never to start logging change history...

New features
------------
- added aspect_ratio to rmagick_analyser

Added support
-------------
- support for ruby 1.9
- added development dependencies to gemspec for easier setting up
