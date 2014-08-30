---
layout: default
title: "Configuration"
tag: customization
---

# Configuration
Configuration defaults should be fairly sensible, but there are a number of things you can adjust to suit your needs. Below is an example with all configuration options used.

{% highlight ruby %}
Dragonfly.app.configure do

  url_format '/images/:job.:ext'                   # defaults to '/:job/:name'
                                                   # NOTE: if you're using models and you want
                                                   # :name, :basename or :ext to appear
                                                   # then you need a xxx_name column for your attachment
  url_host 'http://some.domain.com:4000'           # defaults to nil
  url_path_prefix '/assets'                        # defaults to nil, might be needed if app is mounted under a subdir

  verify_urls true # enabled by default, use false to disable it - adds a SHA parameter on the end of urls

  secret 'This is my secret yeh!!' # used to generate the protective SHA

  response_header 'Cache-Control', 'private'                    # You can set custom response headers
  response_header 'Cache-Control' do |job, request, headers|    # either directly or with a block
    job.image? ? "public, max-age=10000000" : "private"         # setting to nil removes the header
  end

  datastore :memory                   # defaults to :file - see Data stores doc for more details

  processor MyProcessor               # See Processors doc for more details
  generator MyGenerator               # See Generators doc for more details
  analyser MyAnalyser                 # See Analysers doc for more details

  plugin :imagemagick                 # See Plugins doc for more details

  mime_type 'egg', 'fried/egg'        # content with ext ".egg" will be given mime type "fried/egg"

  define_url do |app, job, opts|            # allows overriding urls - defaults to
    if job.step_types == [:fetch]           # app.server.url_for(job, opts)
      app.datastore.url_for(job.uid)
    else
      app.server.url_for(job, opts)
    end
  end

  before_serve do |job, env|          # allows you to do something before content is served
    # do something                    # to override the response, throw :halt with a rack response, e.g.
  end                                 #     throw :halt, [200, {'Content-Type' => 'text/plain'}, ["STUFF"]]

  allow_legacy_urls true              # default to false - allow urls from pre-v0.9.12

  fetch_file_whitelist [              # List of allowed file paths when using fetch_file (strings or regexps)
    "/home/images",
    /public/
  ]

  fetch_url_whitelist      [          # List of allowed urls when using fetch_url (strings or regexps)
    "http://localhost:5000/image.png",
    /some\.domain/
  ]

  dragonfly_url "/here"               # defaults to /dragonfly - set to nil to turn off

  define :first_bytes do |num_bytes|  # define an arbitrary method on Job objects and Attachment objects
    data[0...num_bytes]               # e.g. my_model.attachment.first_bytes
  end

end
{% endhighlight %}
