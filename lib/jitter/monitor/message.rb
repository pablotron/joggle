require 'thread'
require 'pablotron/observable'

module Jitter
  module Monitor
    class Message
      include Pablotron::Observable

      def self.run(client)
        new(client).run
      end

      def initialize(client)
        @client = client
        @client.on(self)
      end

      def run
        queue = Queue.new
        
        Thread.new {
          loop {
            queue << nil
            sleep 180 # TODO: make configurable?
          }
        }

        # loop forever
        loop {
          fire('idle', @client)
          queue.shift
        }
      end

      def reply(who, msg)
        if fire('before_reply', who, msg)
          @client.deliver(who, msg)
          fire('reply', who, msg)
        else
          fire('reply_stopped', who, msg, err)
        end
      end

      ####################
      # jabber listeners #
      ####################

      OP_MATCH = /^\s*\.(register|unregister|list|delete|help)\s*(\S.*|)\s*$/

      def on_jabber_client_message(client, msg)
        if md = msg.body.match(OP_MATCH)
          cmd, who = md[1].downcase, msg.from.to_s
          fire('command', who, cmd, md[2])
        else
          fire('message', msg.from.to_s, msg.body)
        end
      end

      def on_jabber_client_presence(client, old_presence, new_presence)
        fire('presence', new_presence)
      end

      def on_jabber_idle(mon)
        fire('idle', @client)
      end
    end
  end
end
