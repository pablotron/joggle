require 'pablotron/observable'

module Joggle
  module Monitor
    class Socket 
      include Pablotron::Observable

      attr_reader :sockets

      def self.run(sockets, timeout = 60)
        new(sockets, timeout).run
      end

      def initialize(sockets, timeout = 60)
        @sockets = sockets
        @timeout = timeout
      end

      def run
        loop do
          # block until read
          ary = IO.select(@sockets, nil, nil, @timeout)

          # handle each socket
          ary.each do |sock|
            fire('socket_ready', sock)
          end

          # run idle handler
          fire('socket_idle')
        end
      end
    end
  end
end
