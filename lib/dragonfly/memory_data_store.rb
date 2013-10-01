module Dragonfly
  class MemoryDataStore

    def initialize
      @content_store = {}
    end

    def write(content, opts={})
      uid = opts[:uid] || generate_uid
      content_store[uid] = {:content => content.data, :meta => content.meta.dup}
      uid
    end

    def read(uid)
      data = content_store[uid]
      [data[:content], data[:meta]] if data
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
