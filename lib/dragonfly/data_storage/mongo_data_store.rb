require 'mongo'

module Dragonfly
  module DataStorage
    class MongoDataStore

      include Configurable
      include Serializer

      configurable_attr :host
      configurable_attr :port
      configurable_attr :database, 'dragonfly'

      # Mongo gem deprecated ObjectID in favour of ObjectId
      OBJECT_ID = defined?(BSON::ObjectId) ? BSON::ObjectId : BSON::ObjectID
      INVALID_OBJECT_ID = defined?(BSON::InvalidObjectId) ? BSON::InvalidObjectId : BSON::InvalidObjectID

      def initialize(opts={})
        self.host = opts[:host]
        self.port = opts[:port]
        self.database = opts[:database] if opts[:database]
      end

      def store(temp_object, opts={})
        temp_object.file do |f|
          mongo_id = grid.put(f, :metadata => marshal_encode(temp_object.attributes))
          mongo_id.to_s
        end
      end

      def retrieve(uid)
        grid_io = grid.get(bson_id(uid))
        extra = marshal_decode(grid_io.metadata)
        extra[:meta].merge!(:stored_at => grid_io.upload_date)
        [
          grid_io.read,
          extra
        ]
      rescue Mongo::GridFileNotFound, INVALID_OBJECT_ID => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        grid.delete(bson_id(uid))
      rescue Mongo::GridFileNotFound, INVALID_OBJECT_ID => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      private

      def connection
        @connection ||= Mongo::Connection.new(host, port)
      end

      def db
        @db ||= connection.db(database)
      end

      def grid
        @grid ||= Mongo::Grid.new(db)
      end

      def bson_id(uid)
        OBJECT_ID.from_string(uid)
      end

    end
  end
end
