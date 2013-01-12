module Dragonfly
  module DataStorage

    class RelationalDataStore
      include Serializer
      include Configurable

      configurable_attr :class_name, 'RelationalDragonfly'
      configurable_attr :store_meta, true

      def store(temp_object, opts={})
        class_name.constantize.create! { |x|
          x.data = temp_object.data
          x.meta = Marshal.dump(temp_object.meta) if store_meta
        }.id
      rescue ActiveRecord::ActiveRecordError => e
        raise UnableToStore, e.message
      end

      def retrieve(uid)
        record = class_name.constantize.find(uid)
        [record.data, store_meta ? Marshal.load(record.meta) : {}]
      rescue ActiveRecord::ActiveRecordError => e
        raise DataNotFound, "couldn't find file #{uid}"
      end

      def destroy(uid)
        class_name.constantize.find(uid).destroy
      rescue ActiveRecord::ActiveRecordError => e
        raise DataNotFound, e.message
      end
    end

  end
end