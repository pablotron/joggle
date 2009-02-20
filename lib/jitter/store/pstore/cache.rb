require 'digest/md5'

module Jitter
  module Store
    module PStore
      module Cache
        def add_cached(key, row)
          key = cache_store_key(key)

          @store.transaction do |s|
            s[key] = {}.merge(row)
          end
        end

        def get_cached(key)
          key = cache_store_key(key)

          @store.transaction(true) do |s|
            s[key]
          end
        end

        def has_cached?(key)
          key = cache_store_key(key)

          @store.transaction(true) do |s|
            s.root?(key)
          end
        end

        def delete_cached(key)
          key = cache_store_key(key)

          @store.transaction do |s|
            s.delete(key)
          end
        end

        def cache_store_key(key)
          'cache-' << Digest::MD5.hexdigest(key)
        end
      end
    end
  end
end
