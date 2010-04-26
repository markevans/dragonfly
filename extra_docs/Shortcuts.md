Shortcuts
=========

When you call {Dragonfly::App#fetch fetch}, {Dragonfly::ExtendedTempObject#transform transform},
{Dragonfly::UrlHandler#url_for url_for}, (or {Dragonfly::ActiveRecordExtensions::Attachment#url url} on an ActiveRecord attachment), you can specify all the job parameters
necessary to fetch the appropriate content.

The parameters are the following:

  - `:uid` - the uid used by the datastore to retrieve the data (was returned when stored)
  - `:processing_method` - the method used to do the processing
  - `:processing_options` - options hash passed to the processing method
  - `:format` - the format to encode the data with, e.g. 'png'
  - `:encoding` - an options hash passed to the encoder for other options, e.g. bitrate, etc.

Say we have an app configured with the {Dragonfly::Config::RMagickImages RMagickImages}

    app = Dragonfly::App[:my_app]
    app.configure_with(Dragonfly::Config::RMagickImages)

we can call things like

    app.fetch 'some_uid',
      :processing_method => :resize_and_crop,
      :processing_options => {:width => 100, :height => 50, :gravity => 'ne'},
      :format => :jpg,
      :encoding => {:some => 'option'}           # => gets a processed and encoded temp_object
    
    app.url_for 'some_uid',
      :processing_method => :resize_and_crop,
      :processing_options => {:width => 100, :height => 50, :gravity => 'ne'},
      :format => :jpg,
      :encoding => {:some => 'option'}           # => "/images/some_uid.tif?m=resize_and_crop&o[width]=...."

YIKES!!!!!

That's an awful lot of code every time, especially if we reuse the same parameters over and over.
That's why for the arguments after the uid, you can register {Dragonfly::Parameters parameter shortcuts}.

Simple shortcuts
----------------
If we were to use the parameters in the example above a number of times, we could register a simple named shortcut, say 'thumb', using a symbol.

    app.parameters.add_shortcut(:thumb,
      :processing_method => :resize_and_crop,
      :processing_options => {:width => 100, :height => 50, :gravity => 'ne'},
      :format => :jpg,
      :encoding => {:some => 'option'}
    )

We can now use this named shortcut, `:thumb`, in place of the parameters elsewhere

    app.fetch 'some_uid', :thumb           # => gets a processed and encoded temp_object as before    
    app.url_for 'some_uid', :thumb         # => "/images/some_uid.tif?m=resize_and_crop&o[width]=....", as before
    
Complex shortcuts
-----------------
Rather than create a new named shortcut for every different set of parameters, we can make life easier by defining shortcuts
which match a set of arguments, then form parameters from them.

For example, take the shortcut

    app.parameters.add_shortcut(/\d+x\d+/, Symbol) do |geometry, format|
      {
        :processing_method => :my_resize_method,
        :processing_options => {:geometry => geometry},
        :format => format
      }
    end

It will match where there are two arguments, a string matching `/\d+x\d+/` and a symbol, and convert to a hash of job parameters.
Note that the matching arguments are yielded to the block.
So, for example,

    app.url_for('some_uid', '100x50', :jpg)
    
generates the same url as if we'd used

    app.url_for 'some_uid',
      :processing_method => :my_resize_method,
      :processing_options => {:geometry => 100},
      :format => :jpg

The following examples would not match

    app.url_for('some_uid', '100xg50', :jpg)           # '100xg50' doesn't match /\d+x\d+/
    app.url_for('some_uid', '100x50', 'jpg')           # 'jpg' is not a Symbol
    app.url_for('some_uid', '100x50')                  # not enough arguments
    app.url_for('some_uid', '100x50', :jpg, 4)         # too many arguments

The arguments are matched using the `===` operator (as used in `case` statements), which is why, for example, `:jpg` matches `Symbol`.

Regexp shortcuts
----------------
If we register a complex shortcut as a single regexp, then the match data is also yielded, for convenience.

    app.parameters.add_shortcut(/(\d+)x(\d+)/) do |geometry, match_data|
      {
        :processing_method => :my_resize_method,
        :processing_options => {:width => match_data[1], :height => match_data[2]}
      }
    end


Default parameters
------------------
If we've configured a default parameter, e.g.

    app.parameters.default_format = :jpg
    
then this will be used in these methods whenever that parameter is not given, such as in the example above.

Avoiding processing/encoding
----------------------------
If `:processing_method` is set to nil, then no processing takes place when methods like {Dragonfly::App#fetch fetch}, {Dragonfly::ExtendedTempObject#transform transform},
{Dragonfly::UrlHandler#url_for url_for}, and {Dragonfly::ActiveRecordExtensions::Attachment#url url} are called.

Similarly, if `:format` is set to nil, then no encoding takes place.
