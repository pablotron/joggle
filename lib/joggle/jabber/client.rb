require 'pablotron/observable'
require 'xmpp4r'
require 'xmpp4r/roster'

module Joggle
  module Jabber
    class Client
      include Pablotron::Observable

      def initialize(user, pass)
        ::Jabber.debug = true
        Thread.abort_on_exception = false
        # create new jid and client
        jid = ::Jabber::JID.new(user)
        available = ::Jabber::Presence.new.set_type(:available)
        @client = ::Jabber::Client.new(jid)
        @client.connect

        @client.auth(pass)
        @client.send(available)

        roster = ::Jabber::Roster::Helper.new(@client)

        @client.add_message_callback do |msg|
          next unless msg.type == :chat
          fire('jabber_client_message', msg)
        end

        @client.add_presence_callback do |old_p, new_p|
          fire('jabber_client_presence', old_p, new_p)
        end

        roster.add_subscription_request_callback do |item, presence|
          if fire('before_jabber_client_accept_subscription', presence)
            roster.accept_subscription(presence.from)
            fire('jabber_client_accept_subscription', presence)
          end
        end
      end

      def deliver(who, body, type = :chat)
        msg = ::Jabber::Message.new(who, body)
        msg.type = type
        @client.send(msg)
      end
    end
  end
end
