require 'digest/md5'

module Joggle
  module Store
    module PStore
      #
      # Mixin that adds user store methods for PStore backend.
      #
      # Note: You're probably looking for Joggle::Store::PStore::All
      #
      module User
        #
        # Add user to store.
        #
        def add_user(key, row)
          key = user_store_key(key)

          @store.transaction do |s|
            s[key] = row
          end
        end

        #
        # Update user's store entry.
        #
        def update_user(key, row)
          key = user_store_key(key)

          @store.transaction do |s|
            row.each { |k, v| s[key][k] = v }
          end
        end

        #
        # Get information about given user.
        #
        def get_user(key)
          key = user_store_key(key)

          @store.transaction(true) do |s|
            s[key]
          end
        end

        #
        # Is the given user ignored?
        #
        def ignored?(key)
          get_user(key)['ignored']
        end

        #
        # Does the given user exist?
        #
        def has_user?(key)
          key = user_store_key(key)

          @store.transaction(true) do |s|
            s.root?(key)
          end
        end

        #
        # Iterate over all users in store.
        #
        def each_user(&block) 
          users = @store.transaction(true) do |s|
            s.roots.inject([]) do |r, key| 
              (key =~ /^user-/) ? r << s[key] : r
            end
          end

          users.each(&block)
        end

        #
        # Delete given user from store.
        #
        def delete_user(key)
          key = user_store_key(key)

          @store.transaction do |s|
            s.delete(key)
          end
        end

        #
        # Map user key to PStore root key.
        #
        def user_store_key(key)
          'user-' << Digest::MD5.hexdigest(key.gsub(/\/.*$/, ''))
        end
      end
    end
  end
end
