require 'mongo'

module Dragonfly
  module DataStorage
    class MongoDataStore

      include Configurable
      include Serializer

      configurable_attr :host
      configurable_attr :hosts
      configurable_attr :connection_opts, {}
      configurable_attr :port
      configurable_attr :database, 'dragonfly'
      configurable_attr :username
      configurable_attr :password
      configurable_attr :connection
      configurable_attr :db

      # Mongo gem deprecated ObjectID in favour of ObjectId
      OBJECT_ID = defined?(BSON::ObjectId) ? BSON::ObjectId : BSON::ObjectID
      INVALID_OBJECT_ID = defined?(BSON::InvalidObjectId) ? BSON::InvalidObjectId : BSON::InvalidObjectID

      def initialize(opts={})
        self.host = opts[:host]
        self.hosts = opts[:hosts]
        self.connection_opts = opts[:connection_opts] if opts[:connection_opts]
        self.port = opts[:port]
        self.database = opts[:database] if opts[:database]
        self.username = opts[:username]
        self.password = opts[:password]
        self.connection = opts[:connection]
        self.db = opts[:db]
      end

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
      rescue Mongo::GridFileNotFound, INVALID_OBJECT_ID => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        ensure_authenticated!
        grid.delete(bson_id(uid))
      rescue Mongo::GridFileNotFound, INVALID_OBJECT_ID => e
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
        OBJECT_ID.from_string(uid)
      end

    end
  end
end
