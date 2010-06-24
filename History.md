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
