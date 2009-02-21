require 'pablotron/observable'
require 'joggle/monitor/message'
require 'joggle/commands'

module Joggle
  class Engine
    include Pablotron::Observable
    include Commands

    DEFAULTS = {
      'engine.time_format'            => '%H:%M',
      'engine.message_sanity_checks'  => true,
    }

    def initialize(client, tweeter, opt = nil)
      @opt = DEFAULTS.merge(opt || {})

      @monitor = Monitor::Message.new(client)
      @monitor.on(self)

      @tweeter = tweeter
    end

    def run
      @monitor.run
    end

    def reply(who, msg)
      @monitor.reply(who, msg)
    end

    #####################
    # message listeners #
    #####################

    def on_command(mon, who, cmd, arg)
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

    def on_message(mon, who, msg)
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

    def on_idle(mon, client)
      @tweeter.update do |who, id, time, from, msg|
        reply(who, make_response(id, time, from, msg))
      end
    end

    private 

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
