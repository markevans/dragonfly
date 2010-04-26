Encoding
========

'Encoding' encapsulates the idea of a format (e.g. 'png', 'jpeg', 'doc', 'txt', etc.), and any encoding options
(e.g. bit_rate, etc.).

It is up to the encoder to modify the data according to the requested format (note the format is not the same as the mime-type;
the mime-type is detected by the analyser).

The encoder needs to implement a single method, `encode`, which takes a {Dragonfly::ExtendedTempObject temp_object}, a format, and encoding options as arguments.

    def encode(temp_object, format, encoding={})
      #... encode and return a String, File, Tempfile or TempObject
    end

Let's say we register the {Dragonfly::Encoding::RMagickEncoder rmagick encoder} to our dragonfly app called 'images'

    app = Dragonfly::App[:images]
    app.register_encoder(Dragonfly::Encoding::RMagickEncoder)

Then we can encode {Dragonfly::ExtendedTempObject temp_objects} to formats recognised by the RMagickEncoder

    temp_object = app.create_object(File.new('path/to/image.png'))

    temp_object.encode(:png)    # => returns a new temp_object with data encoded as 'png'
    temp_object.encode!(:gif)   # => encodes its own data as a 'png'

    temp_object.encode(:doc)    # => throws :unable_to_handle

The saved configuration {Dragonfly::Config::RMagickImages RMagickImages} registers the above encoder automatically.

Custom Encoders
---------------

To register a custom encoder, derive from {Dragonfly::Encoding::Base Encoding::Base} and register.
As described above, you need to implement the `encode` method.
If the encoder can't handle a format, it should throw `:unable_to_handle`, and control will pass to the previously
registered encoder, and so on.

    class MyEncoder < Dragonfly::Encoding::Base
    
      def encode(temp_object, format, encoding={})
        if format.to_s == 'yo'
          #... encode and return a String, File, Tempfile or TempObject
        else
          throw :unable_to_handle
        end
      end
    
    end
    
    app.register_encoder(MyEncoder)

If the encoder is {Dragonfly::Configurable configurable}, we can configure it as we register it if we need to

    app.register_encoder(MyEncoder) do |e|
      e.some_attribute = 'hello'
    end
