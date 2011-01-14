require 'couchrest'

module Dragonfly
  module DataStorage
    class CouchDataStore

      include Configurable
      include Serializer

      configurable_attr :host, 'localhost'
      configurable_attr :port, '5984'
      configurable_attr :database, 'dragonfly'
      configurable_attr :username
      configurable_attr :password

      def initialize(opts={})
        self.host = opts[:host]
        self.port = opts[:port]
        self.database = opts[:database] if opts[:database]
        self.username = opts[:username]
        self.password = opts[:password]
      end

      def store(temp_object, opts={})
        temp_object.file do |f|
          doc = CouchRest::Document.new(:extra => temp_object.attributes)
          response = db.save_doc(doc)
          doc.put_attachment(temp_object.attributes[:name] || 'file', f, {:content_type => 'application/octet-stream'})
          response['id']
        end
      rescue Exception => e
        raise UnableToStore, "#{e} - #{temp_object.inspect}"
      end

      def retrieve(uid)
        doc = db.get(uid)
        name = doc['_attachments'].keys.first
        extra = symbolize_keys_recursively(doc['extra'])
        [doc.fetch_attachment(name), extra]
      rescue Exception => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        doc = db.get(uid)
        db.delete_doc(doc)
      rescue Exception => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def db
        auth = username.blank? ? nil : "#{username}:#{password}@"
        url = "http://#{auth}#{host}:#{port}"
        
        @db ||= CouchRest.new(url).database!(database)
      end

    private
      # CouchDocument always returns a hash with string keys, so symbolize them
      def symbolize_keys_recursively(hash)
        if hash.is_a? Hash
          hash.inject({}) do |newhash, (k,v)|
            newhash[k.to_sym] = symbolize_keys_recursively(v)
            newhash
          end
        else
          hash
        end
      end
    end
  end
end
