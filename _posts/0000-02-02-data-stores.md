---
layout: default
title:  "Data stores"
tag: customization
---

# Data stores
Data stores are key-value stores that store a piece of content with meta (the value) and reference it with a string uid (the key).

Dragonfly uses these to store data which can later be fetched, e.g.

Given any Dragonfly job
{% highlight ruby %}
job = Dragonfly.app.generate(:text, "lublug").thumb('x200')
{% endhighlight %}

it can be stored with
{% highlight ruby %}
uid = job.store   # ===> "2013/11/06/12_38_39_606_taj.jpg"
{% endhighlight %}

and later fetched with
{% highlight ruby %}
Dragonfly.fetch(uid)
{% endhighlight %}

### Models
Models simply hold a reference to the uid and do the storing and fetching behind the scenes at the appropriate times - see [Models]({{ site.baseurl }}{% post_url 0000-01-04-models %}) for more details.

## File data store
This is the default, but it can be manually configured using
{% highlight ruby %}
Dragonfly.app.configure do
  datastore :file
  # ...
end
{% endhighlight %}

or with options
{% highlight ruby %}
datastore :file,
  :root_path => 'public/dragonfly',    # directory under which to store files
                                       # - defaults to 'dragonfly' relative to current dir
  :server_root => 'public'             # root for urls when serving directly from datastore
                                       #   using remote_url
{% endhighlight %}

You can specify the storage path per-content with
{% highlight ruby %}
uid = job.store(:path => 'my/custom/path')
{% endhighlight %}

To see how to do this with models, see [Models - Storage Options]({{ site.baseurl }}{% post_url 0000-01-04-models %}#storage-options)

## Memory data store
The Memory data store keeps everything in memory and is useful for things like tests.

To use:
{% highlight ruby %}
Dragonfly.app.configure do
  datastore :memory
  # ...
end
{% endhighlight %}

You can also specify the uid on store
{% highlight ruby %}
uid = job.store(:uid => "179")
{% endhighlight %}

## Other data stores
The following datastores previously in Dragonfly core are now in separate gems:

  - [Amazon S3](https://github.com/markevans/dragonfly-s3_data_store)
  - [Couch](https://github.com/markevans/dragonfly-couch_data_store)
  - [Mongo](https://github.com/markevans/dragonfly-mongo_data_store)

Other maintainers have built the following stores:

  - [ActiveRecord](https://github.com/mezis/dragonfly-activerecord)

## Building a custom data store
Data stores need to implement three methods: `write`, `read` and `destroy`.
{% highlight ruby %}
class MyDataStore

  # Store the data AND meta, and return a unique string uid
  def write(content, opts={})
    some_unique_uid = SomeLibrary.store(content.data, meta: content.meta)
    some_unique_uid
  end

  # Retrieve the data and meta as a 2-item array
  def read(uid)
    data = SomeLibrary.get(uid)
    meta = SomeLibrary.get_meta(uid)
    if content
      [
        data,     # can be a String, File, Pathname, Tempfile
        meta      # the same meta Hash that was stored with write
      ]
    else
      nil         # return nil if not found
    end
  end

  def destroy(uid)
    SomeLibrary.delete(uid)
  end

end
{% endhighlight %}

The above should be fairly self-explanatory, but to be a bit more specific:

`write`

  - takes a content object (see <a href="http://rdoc.info/github/markevans/dragonfly/Dragonfly/Content" target="_blank">Dragonfly::Content</a> for more details) and uses a method like `data` (String), `file`, `path` to get its data and `meta` to get its meta
  - also takes an options hash, passing through any options passed to `store`
  - returns a unique String uid

`read`

  - takes a String uid
  - returns a 2-item array; the data in the form of a String, Pathname, File or Tempfile and the meta hash
  - returns nil instead if not found

`destroy`

  - takes a String uid
  - destroys the content

You can also optionally serve data directly from the datastore using

{% highlight ruby %}
Dragonfly.app.remote_url_for(uid)
{% endhighlight %}

or

{% highlight ruby %}
my_model.attachment.remote_url
{% endhighlight %}

provided the data store implements url_for

{% highlight ruby %}
class MyDataStore

  # ...

  def url_for(uid, opts={})
    "http://some.domain/#{uid}"
  end

end
{% endhighlight %}

Both `remote_url_for` and `remote_url` also take an options hash which will be passed through to the data store's `url_for` method.

### Using your custom data store
Your custom data store can be used by a Dragonfly app with
{% highlight ruby %}
Dragonfly.app.configure do
  datastore MyDataStore.new(:some => 'args')
  # ...
end
{% endhighlight %}

or you can register a symbol (which you may want to do if creating a gem)
{% highlight ruby %}
Dragonfly::App.register_datastore(:my_data_store){ MyDataStore }
{% endhighlight %}

so you configure using just the symbol
{% highlight ruby %}
Dragonfly.app.configure do
  datastore :my_data_store, :some => 'args'
  # ...
end
{% endhighlight %}

Note that the data store _class_ is registered with the symbol, not the instance. Any other args are passed straight to the data store's `initialize` method.

### Testing with RSpec
Dragonfly provides a shared rspec example group that you can use to test that your custom data store conforms to the basic spec. Here's a simple example spec file

{% highlight ruby %}
require 'spec_helper'
require 'dragonfly/spec/data_store_examples'

describe MyDataStore do

  before(:each) do
    @data_store = MyDataStore.new
  end

  it_should_behave_like 'data_store'

end
{% endhighlight %}
