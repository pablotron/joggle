require 'joggle/store/pstore/cache'
require 'joggle/store/pstore/message'
require 'joggle/store/pstore/user'

module Joggle
  module Store
    module PStore
      #
      # Wrap all store backends into one object.
      #
      class All
        include Cache
        include Message
        include User

        #
        # Create new Joggle::Store::PStore::All object from given
        # ::PStore object.
        #
        def initialize(store)
          @store = store
        end
      end
    end
  end
end
