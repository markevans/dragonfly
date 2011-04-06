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
        meta = opts[:meta] || {}
        name = meta[:name] || temp_object.original_filename || 'file'
        
        temp_object.file do |f|
          doc = CouchRest::Document.new(:meta => marshal_encode(meta))
          response = db.save_doc(doc)
          doc.put_attachment(name, f, {:content_type => 'application/octet-stream'})
          response['id']
        end
      rescue RuntimeError => e
        raise UnableToStore, "#{e} - #{temp_object.inspect}"
      end

      def retrieve(uid)
        doc = db.get(uid)
        name = doc['_attachments'].keys.first
        [doc.fetch_attachment(name), marshal_decode(doc['meta'])]
      rescue RestClient::ResourceNotFound => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        doc = db.get(uid)
        db.delete_doc(doc)
      rescue RestClient::ResourceNotFound => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def db
        @db ||= begin
          auth = username.blank? ? nil : "#{username}:#{password}@"
          url = "http://#{auth}#{host}:#{port}"
          CouchRest.new(url).database!(database)
        end
      end

    end
  end
end
