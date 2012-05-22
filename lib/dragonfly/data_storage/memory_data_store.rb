module Dragonfly
  module DataStorage
    class MemoryDataStore

      def initialize
        @content_store = Hash.new{ raise DataNotFound }
      end

      def store(temp_object, opts={})
        uid = generate_uid
        content_store[uid] = {:content => temp_object.data, :meta => temp_object.meta}
        uid
      end

      def retrieve(uid)
        data = content_store[uid]
        [
          data[:content],
          data[:meta]
        ]
      end

      def destroy(uid)
        content_store.delete(uid)
      end

      private

      attr_reader :content_store

      def generate_uid
        @uid_count ||= 0
        @uid_count += 1
        @uid_count.to_s
      end

    end
  end
end
