# coding: utf-8

require 'rails/cache/tags/tag'
require 'lru_redux'

module Rails
  module Cache
    module Tags
      class Set
        # @param [ActiveSupport::Cache::Store] store
        def initialize(store)
          @store = store
          @cache = ::LruRedux::TTL::Cache.new(0, 0.seconds)
        end

        def current(tag)
          @store.fetch_without_tags(tag.to_key) { 1 }.to_i
        end

        def expire(tag)
          version = current(tag) + 1

          @store.write_without_tags(tag.to_key, version, :expires_in => nil)

          version
        end

        def check(entry)
          return entry unless entry.is_a?(Store::Entry)
          return entry.value if entry.tags.blank?

          tags = Tag.build(entry.tags.keys)

          saved_versions = entry.tags.values.map(&:to_i)

          saved_versions == current_versions(tags) ? entry.value : nil
        end

        private

        def current_versions(tags)
          keys = *Array.wrap(tags).map(&:to_key)
          @cache.getset(keys.join) do
            @store.read_multi_without_tags(keys).values.map(&:to_i)
          end
        end
      end # class Set
    end # module Tags
  end # module Cache
end # module Rails