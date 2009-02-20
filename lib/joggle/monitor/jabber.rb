require 'pablotron/observable'
require 'joggle/monitor/socket'

module Joggle
  module Monitor
    class Jabber 
      include Pablotron::Observable

      DEFAULT_TIMEOUT = 60

      attr_reader :client, :timeout

      def self.run(client, timeout = nil)
        new(client, timeout).run
      end

      def initialize(client, timeout = nil)
        @client = client
        @timeout ||= DEFAULT_TIMEOUT
      end

      def run
        # create a new socket monitor and bind it to me
        so = Monitor::Socket.new([client_socket], @timeout)

        # bind it to me
        so.on(self)

        # run forever
        so.run
      end

      ####################
      # socket listeners #
      ####################
       
      def on_socket_ready(mon, sock)
        # make sure this is our socket
        return unless sock != client_socket

        # handle presense updates
        @client.presence_updates.each do |update|
          fire('jabber_presence_update', client, update)
        end
        
        # handle received messages
        @client.received_messages.each do |msg|
          next if msg.type != :chat
          fire('jabber_message_received', @client, msg)
        end
      end

      def on_socket_idle(mon)
        fire('jabber_idle', @client)
      end

      private

      def client_socket
        @client.instance_eval { @socket }
      end
    end
  end
end
