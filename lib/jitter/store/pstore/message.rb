require 'digest/md5'

module Jitter
  module Store
    module PStore
      module Message
        def add_message(key, row)
          key = message_store_key(key)

          @store.transaction do |s|
            s[key] = row
          end
        end

        def has_message?(key)
          key = message_store_key(key)

          @store.transaction(true) do |s|
            s.root?(key)
          end
        end

        def delete_message(key)
          key = message_store_key(key)

          @store.transaction do |s|
            s.delete(key)
          end
        end

        def message_store_key(key)
          'message-' << Digest::MD5.hexdigest(key.to_s)
        end
      end
    end
  end
end
