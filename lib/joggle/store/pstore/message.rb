require 'digest/md5'

module Joggle
  module Store
    module PStore
      #
      # Mixin that implements message store methods for pstore objects
      #
      # Note: You're probably looking for Joggle::Store::PStore::All
      #
      module Message
        #
        # Add message to store.
        #
        def add_message(key, row)
          key = message_store_key(key)

          @store.transaction do |s|
            s[key] = row
          end
        end

        #
        # Does the given message exist in this store?
        #
        def has_message?(key)
          key = message_store_key(key)

          @store.transaction(true) do |s|
            s.root?(key)
          end
        end

        #
        # Delete the given message.
        #
        def delete_message(key)
          key = message_store_key(key)

          @store.transaction do |s|
            s.delete(key)
          end
        end

        #
        # Map given key to PStore root key.
        #
        def message_store_key(key)
          'message-' << Digest::MD5.hexdigest(key.to_s)
        end
      end
    end
  end
end
