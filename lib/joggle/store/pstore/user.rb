require 'digest/md5'

module Joggle
  module Store
    module PStore
      module User
        def add_user(key, row)
          key = user_store_key(key)

          @store.transaction do |s|
            s[key] = row
          end
        end

        def update_user(key, row)
          key = user_store_key(key)

          @store.transaction do |s|
            row.each { |k, v| s[key][k] = v }
          end
        end

        def get_user(key)
          key = user_store_key(key)

          @store.transaction(true) do |s|
            s[key]
          end
        end

        def ignored?(key)
          get_user(key)['ignored']
        end

        def has_user?(key)
          key = user_store_key(key)

          @store.transaction(true) do |s|
            s.root?(key)
          end
        end

        def each_user(&block) 
          users = @store.transaction(true) do |s|
            s.roots.inject([]) do |r, key| 
              (key =~ /^user-/) ? r << s[key] : r
            end
          end

          users.each(&block)
        end

        def delete_user(key)
          key = user_store_key(key)

          @store.transaction do |s|
            s.delete(key)
          end
        end

        def user_store_key(key)
          'user-' << Digest::MD5.hexdigest(key)
        end
      end
    end
  end
end
