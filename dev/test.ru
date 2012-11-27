require "rubygems"
require "bundler/setup"
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'dragonfly'

ROOT = (File.expand_path('../..', __FILE__))
APP = Dragonfly[:images].configure_with(:imagemagick).configure do
  url_format '/images/:job'
  # c.allow_fetch_file = true
end

def row(geometry)
  image = APP.fetch_file(ROOT + '/samples/beach.png').thumb('100x100#')
  %(<tr>
    <th>#{geometry}</th>
    <th><img src="#{image.url}" /></th>
    <th><img src="#{image.thumb(geometry).url}" /></th>
  </tr>)
end

use Dragonfly::Middleware, :images
run proc{[
  200,
  {'Content-Type' => 'text/html'},
  [%(
    <table>
      <tr>
        <th>Geometry</th>
        <th>Original(100x100)</th>
        <th>Thumb</th>
      </tr>
    #{[
      row('80x40#'),
      row('80x40#c'),
      row('80x40#n'),
      row('80x40#s'),
      row('40x80#e'),
      row('40x80#w'),
      row('40x40nw'),
      row('40x40ne'),
      row('40x40se'),
      row('40x40sw'),
      # row('80x60'),
      # row('80x60!'),
      # row('80x'),
      # row('x60'),
      # row('80x60>'),
      # row('80x60<'),
      # row('50x50%'),
      # row('80x60^'),
      # row('2000@'),
      # row('80x60#'),
      # row('80x60#ne'),
      # row('80x60se'),
      # row('80x60+5+35')
    ].join}
    </table>
  )]
]}
