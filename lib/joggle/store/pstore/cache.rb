require 'digest/md5'

module Joggle
  module Store
    module PStore
      #
      # Mixin that implements cache store methods for PStore backend.
      #
      # Note: You're probably looking for Joggle::Store::PStore::All
      #
      module Cache
        #
        # Add cache entry.
        #
        def add_cached(key, row)
          key = cache_store_key(key)

          @store.transaction do |s|
            s[key] = {}.merge(row)
          end
        end

        #
        # Get cache entry.
        #
        def get_cached(key)
          key = cache_store_key(key)

          @store.transaction(true) do |s|
            s[key]
          end
        end

        #
        # Does the given entry exist?
        #
        def has_cached?(key)
          key = cache_store_key(key)

          @store.transaction(true) do |s|
            s.root?(key)
          end
        end

        #
        # Delete the given entry.
        #
        def delete_cached(key)
          key = cache_store_key(key)

          @store.transaction do |s|
            s.delete(key)
          end
        end

        #
        # Map the given key to a pstore root key.
        #
        def cache_store_key(key)
          'cache-' << Digest::MD5.hexdigest(key)
        end
      end
    end
  end
end
