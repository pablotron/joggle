begin
  require 'rubygems'
rescue LoadError
  # ignore missing rubygems
end

require 'pstore'
require 'logger'
require 'fileutils'
require 'pablotron/cache'
require 'joggle/version'
require 'joggle/store/pstore/all'
require 'joggle/jabber/client'
require 'joggle/twitter/fetcher'
require 'joggle/twitter/engine'
require 'joggle/engine'

module Joggle
  module Runner
    #
    # Basic PStore-backed runner.  Creates all necessary objects from
    # given config and binds them together.
    #
    class PStore
      PATHS = {
        'store' => ENV['JOGGLE_STORE_PATH'] || '~/.joggle/joggle.pstore',
        'log'   => ENV['JOGGLE_LOG_PATH'] || '~/.joggle/joggle.log',
      }

      DEFAULTS = {
        # store configuration
        'runner.store.path'       => File.expand_path(PATHS['store']),

        # log configuration
        'runner.log.path'         => File.expand_path(PATHS['log']),
        # FIXME: change to INFO
        'runner.log.level'        => 'DEBUG',
        'runner.log.format'       => '%Y-%m-%dT%H:%M:%S',

        # cache configuration
        'runner.cache.headers'    => {
          # 'user-agent' => "Joggle/#{Joggle::VERSION}",
          'user-agent' => "Joggle/#{Joggle::VERSION}",
        },
      }

      attr_reader :log, :store, :cache, :fetcher, :tweeter, :client, :engine

      #
      # Create and run PStore runner object.
      #
      def self.run(opt = nil)
        new(opt).run
      end

      PATH_KEYS = %w{store log}

      #
      # Create new PStore runner object from the given options.
      #
      def initialize(opt = nil)
        @opt = DEFAULTS.merge(opt || {})

        # make sure paths exist
        PATH_KEYS.each do |key|
          FileUtils.mkdir_p(File.dirname(@opt["runner.#{key}.path"]), {
            # restict access to owner
            :mode => 0700
          })
        end

        # create logger
        @log = Logger.new(@opt['runner.log.path'])
        @log.level = Logger.const_get(@opt['runner.log.level'].upcase)
        @log.datetime_format = @opt['runner.log.format']
        @log.info('Log started.')

        # create backing store
        path = @opt['runner.store.path'] 
        @log.debug("Creating backing store \"#{path}\".")
        pstore = ::PStore.new(path)
        @store = Store::PStore::All.new(pstore)
      end

      #
      # Run this runner.
      #
      def run
        # create cache
        @log.debug('Creating cache.')
        @cache = Pablotron::Cache.new(@store, @opt['runner.cache.headers'])

        # create fetcher
        @log.debug('Creating twitter fetcher.')
        @fetcher = Twitter::Fetcher.new(@store, @cache, @opt)

        # create twitter engine
        @log.debug('Creating twitter engine.')
        @tweeter = Twitter::Engine.new(@store, @fetcher, @opt)
        @tweeter.on(self)

        # create jabber client
        @log.debug('Creating jabber client.')
        @client = Jabber::Client.new(@opt['runner.client.user'], @opt['runner.client.pass'], @opt)
        @client.on(self)

        # create new joggle engine
        @log.debug('Creating engine.')
        @engine = Engine.new(@client, @tweeter)
        @engine.on(self)

        @log.debug('Running engine.')
        @engine.run
      end

      #################
      # log listeners #
      #################
      
      #
      # Log twitter_engine_register_user events.
      #
      # Note: This method is a listener for Twitter::Engine objects; you
      # should never call it directly.
      #
      def on_twitter_engine_register_user(e, who, user, pass)
        pre = '<Twitter::Engine>'
        @log.info("#{pre} Registering user: #{who} (xmpp) => #{user} (twitter).")
      end
      
      #
      # Log twitter_engine_unregister_user events.
      #
      # Note: This method is a listener for Twitter::Engine objects; you
      # should never call it directly.
      #
      def on_twitter_engine_unregister_user(e, who)
        pre = '<Twitter::Engine>'
        @log.info("#{pre} Unregistering user: #{who} (xmpp).")
      end

      #
      # Log twitter_engine_tweet events.
      #
      # Note: This method is a listener for Twitter::Engine objects; you
      # should never call it directly.
      #
      def on_twitter_engine_tweet(e, who, msg)
        pre = '<Twitter::Engine>'
        @log.info("#{pre} Tweet: #{who}: #{msg}.")
      end

      #
      # Log twitter_engine_update events.
      #
      # Note: This method is a listener for Twitter::Engine objects; you
      # should never call it directly.
      #
      def on_twitter_engine_update(e, user)
        pre = '<Twitter::Engine>'
        @log.info("#{pre} Updating: #{user['who']}.")
      end

      #
      # Log engine_update_error events.
      #
      # Note: This method is a listener for Joggle::Engine objects; you
      # should never call it directly.
      #
      def on_engine_update_error(e, err) 
        pre = '<Engine>'
        @log.warn("#{pre} Twitter update failed: #{err}.")
      end

      #
      # Log engine_reply events.
      #
      # Note: This method is a listener for Joggle::Engine objects; you
      # should never call it directly.
      #
      def on_engine_reply(e, who, msg)
        pre = '<Engine>'
        @log.info("#{pre} Reply: #{who}: #{msg}.")
      end

      #
      # Log engine_reply_error events.
      #
      # Note: This method is a listener for Joggle::Engine objects; you
      # should never call it directly.
      #
      def on_engine_reply_error(e, who, msg, err) 
        pre = '<Engine>'
        @log.warn("#{pre} Reply Error: Couldn't send reply \"#{msg}\" to #{who}: #{err}.")
      end

      #
      # Log engine_idle events (debugging only).
      #
      # Note: This method is a listener for Joggle::Engine objects; you
      # should never call it directly.
      #
      def on_engine_command(e, who, cmd, arg)
        pre = '<Engine>'
        @log.debug("#{pre} Command: #{who}: cmd = #{cmd}, arg = #{arg}.")
      end

      #
      # Log engine_command events.
      #
      # Note: This method is a listener for Joggle::Engine objects; you
      # should never call it directly.
      #
      def on_engine_command(e, who, cmd, arg)
        pre = '<Engine>'
        @log.info("#{pre} Command: #{who}: cmd = #{cmd}, arg = #{arg}.")
      end

      #
      # Log engine_message events.
      #
      # Note: This method is a listener for Joggle::Engine objects; you
      # should never call it directly.
      #
      def on_engine_message(e, who, msg)
        pre = '<Engine>'
        @log.info("#{pre} Message: #{who}: #{msg}.")
      end

      #
      # Log engine_ignored_message events.
      #
      # Note: This method is a listener for Joggle::Engine objects; you
      # should never call it directly.
      #
      def on_engine_ignored_message(e, who, msg)
        pre = '<Engine>'
        @log.info("#{pre} IGNORED: #{who}: #{msg}.")
      end

      #
      # Log engine_ignored_subscription events.
      #
      # Note: This method is a listener for Joggle::Engine objects; you
      # should never call it directly.
      #
      def on_engine_ignored_subscription(e, who)
        pre = '<Engine>'
        @log.info("#{pre} IGNORED: #{who} (subscription)")
      end
    end
  end
end
