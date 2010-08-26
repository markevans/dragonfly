Sinatra
=======
You can use {Dragonfly::Job Job}'s `to_response` method like so:

    app = Dragonfly[:images].configure_with(:rmagick)

    get '/images/:size.:format' do |size, format|
      app.fetch_file('~/some/image.png').thumb(size).encode(format).to_response(env)
    end

`to_response` returns a rack-style response array with status, headers and body.

NOTE: uids from the datastore currently have slashes and dots in them so may cause problems when using ':uid' as
a path segment.

or you can mount as a middleware, like in rails:

    Dragonfly[:images].configure_with(:rmagick) do |c|
      c.url_path_prefix = '/media'
    end

    use Dragonfly::Middleware, :images, '/media'

    get '/' #... do
      # ...
