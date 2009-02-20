require 'jitter/store/pstore/cache'
require 'jitter/store/pstore/message'
require 'jitter/store/pstore/user'

module Jitter
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
