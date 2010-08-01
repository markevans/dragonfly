Data Storage
============

Each dragonfly app has a datastore.

    Dragonfly[:my_app_name].datastore
    
By default it uses the file data store, but you can configure it to use
a custom data store (e.g. S3, SQL, CouchDB, etc.) by registering one with the correct interface, namely
having `store`, `retrieve` and `destroy`.

    class MyDataStore < Dragonfly::DataStorage::Base

      def store(temp_object)
        # ... use temp_object.data, temp_object.file, or temp_object.path and store
        'return_some_unique_uid'
      end

      def retrieve(uid)
        # find the content and return either a data string, a file, a tempfile or a Dragonfly::TempObject
      end
  
      def destroy(uid)
        # find the content and destroy
      end

    end

You can now configure the app to use this datastore like so

    Dragonfly[:my_app_name].datastore = MyDataStore.new

If you want your datastore to be configurable, you can include the {Dragonfly::Configurable Configurable} module.
