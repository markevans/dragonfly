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
        self.host = opts[:host] if opts[:host]
        self.port = opts[:port] if opts[:port]
        self.database = opts[:database] if opts[:database]
        self.username = opts[:username]
        self.password = opts[:password]
      end

      def store(temp_object, opts={})
        name = temp_object.name || 'file'
        content_type = opts[:content_type] || opts[:mime_type] || 'application/octet-stream'
        
        temp_object.file do |f|
          doc = CouchRest::Document.new(:meta => marshal_encode(temp_object.meta))
          response = db.save_doc(doc)
          doc.put_attachment(name, f.dup, :content_type => content_type)
          form_uid(response['id'], name)
        end
      rescue RuntimeError => e
        raise UnableToStore, "#{e} - #{temp_object.inspect}"
      end

      def retrieve(uid)
        doc_id, attachment = parse_uid(uid)
        doc = db.get(doc_id)
        [doc.fetch_attachment(attachment), marshal_decode(doc['meta'])]
      rescue RestClient::ResourceNotFound => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        doc_id, attachment = parse_uid(uid)
        doc = db.get(doc_id)
        db.delete_doc(doc)
      rescue RestClient::ResourceNotFound => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def db
        @db ||= begin
          url = "http://#{auth}#{host}:#{port}"
          CouchRest.new(url).database!(database)
        end
      end

      def url_for(uid, opts={})
        doc_id, attachment = parse_uid(uid)
        "http://#{host}:#{port}/#{database}/#{doc_id}/#{attachment}"
      end
      
      private
      
      def auth
        username.blank? ? nil : "#{username}:#{password}@"
      end
      
      def form_uid(doc_id, attachment)
        "#{doc_id}/#{attachment}"
      end
      
      def parse_uid(uid)
        doc_id, attachment = uid.split('/')
        [doc_id, (attachment || 'file')]
      end

    end
  end
end
