require 'mongo'

module Dragonfly
  module DataStorage
    class MongoDataStore < Base

      include Configurable
      include Serializer

      configurable_attr :database, 'dragonfly'

      def initialize(opts={})
        self.database = opts[:database] if opts[:database]
      end

      def store(temp_object)
        temp_object.file do |f|
          mongo_id = grid.put(f, :filename => temp_object.name, :metadata => marshal_encode(temp_object.meta))
          mongo_id.to_s
        end
      end

      def retrieve(uid)
        grid_io = grid.get(bson_id(uid))
        [
          grid_io.read,
          {
            :name => grid_io.filename,
            :meta => marshal_decode(grid_io.metadata).merge(:stored_at => grid_io.upload_date),
          }
        ]
      rescue Mongo::GridFileNotFound, BSON::InvalidObjectID => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      def destroy(uid)
        grid.delete(bson_id(uid))
      rescue Mongo::GridFileNotFound, BSON::InvalidObjectID => e
        raise DataNotFound, "#{e} - #{uid}"
      end

      private
      
      def grid
        @grid ||= (
          db = Mongo::Connection.new.db(database)
          Mongo::Grid.new(db)
        )
      end
      
      def bson_id(uid)
        BSON::ObjectID.from_string(uid)
      end
      
    end
  end
end
