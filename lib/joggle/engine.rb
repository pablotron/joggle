require 'pablotron/observable'
require 'joggle/commands'

module Joggle
  #
  # Joggle engine object.  This is where the magic happens.
  #
  class Engine
    include Pablotron::Observable
    include Commands

    DEFAULTS = {
      'engine.time_format'            => '%H:%M',
      'engine.message_sanity_checks'  => true,
      'engine.update_interval'        => 5,
    }

    #
    # Create a new Joggle engine object.
    #
    def initialize(client, tweeter, opt = nil)
      @opt = DEFAULTS.merge(opt || {})

      @client = client
      @client.on(self)

      @tweeter = tweeter
    end

    #
    # Run forever.
    #
    def run
      loop {
        # check for updates
        update

        # wait until next update
        delay
      }
    end

    #
    # Reply to a user with the given message.
    #
    def reply(who, msg)
      if fire('engine_before_reply', who, msg)
        @client.deliver(who, msg)
        fire('engine_reply', who, msg)
      else
        fire('engine_reply_stopped', who, msg, err)
      end
    end

    ####################
    # client listeners #
    ####################

    COMMAND_REGEX = /^\s*\.(\w+)\s*(\S.*|)\s*$/

    #
    # Jabber message listener callback.
    #
    def on_jabber_client_message(client, msg)
      if md = msg.body.match(COMMAND_REGEX)
        cmd, who = md[1].downcase, msg.from.to_s
        handle_command(who, cmd, md[2])
      else
        handle_message(msg.from.to_s, msg.body)
      end
    end

    private 

    def handle_command(who, cmd, arg)
      # build method name
      meth = "do_#{cmd}"

      if respond_to?(meth)
        # return if @tweeter.ignored?(who)
        fire('engine_command', who, cmd, arg)
        send("do_#{cmd}", who, arg)
      else
        # unknown commands
        # FIXME: is this the correct behavior?
        reply(who, "Unknown command: #{cmd}")
      end
    end

    def handle_message(who, msg)
      # remove extraneous whitespace
      msg, out_msg = msg.strip, nil

      # notify listeners
      fire('engine_message', who, msg)
      
      # make sure message is sane
      if sane_message?(msg)
        begin
          row = @tweeter.tweet(who, msg)
          out = "Done (id: #{row['id']})"
        rescue Exception => err
          out = "Error: #{err}"
        end
      else
        out = "Error: Message is too short (try adding more words)"
      end

      # send reply
      reply(who, out)
    end


    def update
      if fire('before_engine_update')
        @tweeter.update do |who, id, time, from, msg|
          reply(who, make_response(id, time, from, msg))
        end

        fire('engine_update')
      else
        fire('engine_update_stopped')
      end
    end

    def delay
      fire('engine_idle')

      minutes = @opt['engine.update_interval']
      minutes = 3 if minutes < 3

      sleep(minutes * 60)
    end

    #
    # Constraints to prevent garbage tweets.
    #
    MESSAGE_SANITY_CHECKS = [
      # contains at least three consecutive word characters
      proc { |m| m.match(/\w{3}/) },

      # contains at least three, at least two of which are longer than
      # three characters
      proc { |m| 
        words = m.split(/\s+/)
        (words.size > 2) && (words.select { |w| w && w.size > 2 }.size > 1)
      },
    ]

    def sane_message?(msg)
      # are sanity checks enabled?
      return true unless @opt['engine.message_sanity_checks']

      # pass message through all sanity checks
      MESSAGE_SANITY_CHECKS.all? { |p| p.call(msg) }
    end

    def make_response(id, time, from, msg)
      stamp = time.strftime(@opt['engine.time_format'])
      "%s: %s (%s, #%d)" % [from, msg, stamp, id]
    end
  end
end
