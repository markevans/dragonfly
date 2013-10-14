require "rubygems"
require "bundler/setup"
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'dragonfly'

Dragonfly.logger = Logger.new(STDOUT)
Dragonfly.app.configure do
  plugin :imagemagick
  url_format '/images/:job'
  fetch_file_whitelist [String]
end

class App
  def call(env)
    image = Dragonfly.app.fetch_file('grid.jpg')
    request = Rack::Request.new(env)
    error = nil
    if request['code']
      begin
        img_src = eval("image.#{request['code']}").url
      rescue StandardError => e
        error = e
      end
    end
    [
      200,
      {'Content-Type' => 'text/html'},
      [%(
        <style>
          form, input {
            font-size: 32px;
          }
          p.error {
            color: red;
            font-size: 24px;
          }
        </style>
        <p class="error">#{error}</p>
        <table>
          <tr>
            <th>Original (#{image.width}x#{image.height})</th>
            <td><img src="#{image.url}" /></td>
          </tr>
          <tr>
            <th><form>image.<input size="40" autofocus placeholder="thumb('200x100')" name="code" value="#{request['code']}" /></form></th>
            <td><img src="#{img_src}" /></td>
          </tr>
        </table>
      )]
    ]
  end
end

use Dragonfly::Middleware
run App.new

