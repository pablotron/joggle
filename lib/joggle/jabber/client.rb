require 'joggle/pablotron/observable'
require 'xmpp4r'
require 'xmpp4r/roster'

module Joggle
  module Jabber
    #
    # Simple XMPP client.
    #
    class Client
      include Joggle::Pablotron::Observable

      DEFAULTS = {
        'jabber.client.debug' => false,
      }

      #
      # Create a new Jabber::Client object.
      #
      # Example:
      #
      #   # create new client object
      #   client = Client.new('foo@example.com', 'mysekretpassword')
      #
      def initialize(user, pass, opt = {})
        # parse options
        @opt = DEFAULTS.merge(opt || {})

        # enable debugging to stdout
        if @opt['jabber.client.debug']
          ::Jabber.debug = true
        end

        # FIXME: this belongs elsewhere
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
          from = presence.from

          if fire('before_jabber_client_accept_subscription', from)
            roster.accept_subscription(from)
            fire('jabber_client_accept_subscription', from)
          end
        end
      end

      #
      # Deliver jabber message to user.
      #
      # Example:
      #
      #   # send message
      #   client.deliver('foo@example.com', 'hey there!')
      #
      def deliver(who, body, type = :chat)
        msg = ::Jabber::Message.new(who, body)
        msg.type = type
        @client.send(msg)
      end
    end
  end
end
