require 'joggle/store/pstore/cache'
require 'joggle/store/pstore/message'
require 'joggle/store/pstore/user'

module Joggle
  module Store
    module PStore
      class All
        include Cache
        include Message
        include User

        def initialize(store)
          @store = store
        end
      end
    end
  end
end
