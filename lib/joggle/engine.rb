require 'pablotron/observable'
require 'joggle/monitor/message'
require 'joggle/commands'

module Joggle
  class Engine
    include Pablotron::Observable
    include Commands

    DEFAULTS = {
      'engine.time_format' => '%H:%M',
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
      # return if @tweeter.ignored?(who)
      fire('engine_command', who, cmd, arg)
      send("do_#{cmd}", who, arg)
    end

    def on_message(mon, who, msg)
      fire('engine_message', who, msg)
      @tweeter.tweet(who, msg)
    end

    def on_idle(mon, client)
      @tweeter.update do |who, id, time, from, msg|
        reply(who, make_response(id, time, from, msg))
      end
    end

    private 

    def make_response(id, time, from, msg)
      stamp = time.strftime(@opt['engine.time_format'])
      "%s: %s (%s, #%d)" % [from, msg, stamp, id]
    end
  end
end
