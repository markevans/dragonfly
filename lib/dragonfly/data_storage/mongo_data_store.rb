require 'mongo'

module Dragonfly
  module DataStorage
    class MongoDataStore

      include Serializer

      def initialize(opts={})
        @host            = opts[:host]
        @hosts           = opts[:hosts]
        @connection_opts = opts[:connection_opts] || {}
        @port            = opts[:port]
        @database        = opts[:database] || 'dragonfly'
        @username        = opts[:username]
        @password        = opts[:password]
        @connection      = opts[:connection]
        @db              = opts[:db]
      end

      attr_accessor :host, :hosts, :connection_opts, :port, :database, :username, :password

      def store(temp_object, opts={})
        ensure_authenticated!
        content_type = opts[:content_type] || opts[:mime_type] || 'application/octet-stream'
        temp_object.file do |f|
          mongo_id = grid.put(f, :content_type => content_type,
                                 :metadata => marshal_encode(temp_object.meta))
          mongo_id.to_s
        end
      end

      def retrieve(uid)
        ensure_authenticated!
        grid_io = grid.get(bson_id(uid))
        meta = marshal_decode(grid_io.metadata)
        meta.merge!(:stored_at => grid_io.upload_date)
        [
          grid_io.read,
          meta
        ]
      rescue Mongo::GridFileNotFound, BSON::InvalidObjectId => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        ensure_authenticated!
        grid.delete(bson_id(uid))
      rescue Mongo::GridFileNotFound, BSON::InvalidObjectId => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def connection
        @connection ||= if hosts
          Mongo::ReplSetConnection.new(hosts, connection_opts)
        else
          Mongo::Connection.new(host, port, connection_opts)
        end
      end

      def db
        @db ||= connection.db(database)
      end

      def grid
        @grid ||= Mongo::Grid.new(db)
      end

      private

      def ensure_authenticated!
        if username
          @authenticated ||= db.authenticate(username, password)
        end
      end

      def bson_id(uid)
        BSON::ObjectId.from_string(uid)
      end

    end
  end
end
