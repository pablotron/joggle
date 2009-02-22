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
      # output time format
      'engine.time_format'              => '%H:%M',

      # enable sanity checks
      'engine.message_sanity_checks'    => true,

      # update every 60 minutes by default
      'engine.update.default'           => 60,

      # time ranges for updates
      'engine.update.range'             => {
        # from midnight until 2am, update every 10 minutes
        '0-2'     => 10,

        # from 9am until 10pm, update every 5 minutes
        '8-22'    => 5,

        # from 10pm until midnight, update every 10 minutes
        '22-24'   => 10,
      },
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
        # check for updates (if we need to)
        if need_update?
          update
        end

        # sleep for one minute
        sleep 60
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

    #
    # Jabber subscription listener callback.
    #
    def on_before_jabber_client_accept_subscription(client, who)
      allowed =  @opt['engine.allow']

      if allowed && allowed.size > 0
        return if allowed.any? { |str| who.match(/^#{str}/i) }
        raise Pablotron::Observable::StopEvent, "denied subscription: #{who}"
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
          out = "Error: #{err.backtrace.first}: #{err.message}"
        end
      else
        out = "Error: Message is too short (try adding more words)"
      end

      # send reply
      reply(who, out)
    end

    #
    # Get the update interval for the given time
    # 
    def get_update_interval(time = Time.now)
      hour = time.hour
      default, ranges = %w{default range}.map { |k| @opt["engine.update.#{k}"] }

      if ranges 
        ranges.each do |key, val|
          # get start/end hour
          hours = key.split(/\s*-\s*/).map { |s| s.to_i }

          # if this interval matches the given time, return it
          if hour >= hours.first && hour <= hours.last
            return val.to_i
          end
        end
      end

      # return the default interval
      default.to_i
    end

    #
    # Do we need an update?
    #
    def need_update?
      return true unless @last_update

      # get the current timestamp and the current update interval 
      now = Time.now
      m = get_update_interval(now)
      m = 5 if m < 5

      # File.open('/tmp/foo.log', 'a') do |fh|
      #   fh.puts "now = %s, next_update = %s" % [
      #     Time.now.strftime('%Y-%m-%dT%H:%M:%S'),
      #     Time.at(@last_update + (m * 60)).strftime('%Y-%m-%dT%H:%M:%S'),
      #   ]
      # end

      # return true if the last update was more than m minutes ago
      @last_update + (m * 60) < now.to_i
    end

    def update
      if fire('before_engine_update')
        # save last update time
        @last_update = Time.now.to_i

        # send updates
        @tweeter.update do |who, id, time, from, msg|
          reply(who, make_response(id, time, from, msg))
        end

        # notify listeners
        fire('engine_update')
      else
        fire('engine_update_stopped')
      end
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
