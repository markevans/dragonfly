require 'couchrest'
require 'dragonfly/serializer'
require 'dragonfly/utils'

module Dragonfly
  module DataStorage
    class CouchDataStore

      include Serializer

      def initialize(opts={})
        @host = opts[:host] || 'localhost'
        @port = opts[:port] || '5984'
        @database = opts[:database] || 'dragonfly'
        @username = opts[:username]
        @password = opts[:password]
      end

      attr_reader :host, :port, :database, :username, :password

      def write(content, opts={})
        name = content.name || 'file'

        content.file do |f|
          doc = CouchRest::Document.new(:meta => content.meta)
          response = db.save_doc(doc)
          doc.put_attachment(name, f.dup, :content_type => content.mime_type)
          form_uid(response['id'], name)
        end
      end

      def retrieve(content, uid)
        doc_id, attachment = parse_uid(uid)
        doc = db.get(doc_id)
        content.update(doc.fetch_attachment(attachment), extract_meta(doc))
      rescue RestClient::ResourceNotFound => e
        throw :not_found, uid
      end

      def destroy(uid)
        doc_id, attachment = parse_uid(uid)
        doc = db.get(doc_id)
        db.delete_doc(doc)
      rescue RestClient::ResourceNotFound => e
        Dragonfly.warn("#{self.class.name} destroy error: #{e}")
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

      def extract_meta(doc)
        meta = doc['meta']
        meta = Utils.stringify_keys(marshal_b64_decode(meta)) if meta.is_a?(String) # Deprecated encoded meta
        meta
      end

    end
  end
end

