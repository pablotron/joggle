require 'net/http'
require 'time'
require 'joggle/pablotron/observable'

module Joggle
  module Twitter
    #
    # Twitter engine object.
    #
    class Engine
      include Joggle::Pablotron::Observable

      DEFAULTS = {
        # update interval, in minutes
        'twitter.engine.update_interval' => 5,
      }

      #
      # Create new twitter engine.
      #
      def initialize(user_store, fetcher, opt = nil)
        @opt = DEFAULTS.merge(opt || {})
        @store = user_store
        @fetcher = fetcher
      end

      #
      # Is the given Jabber user ignored?
      #
      def ignored?(who)
        if rec = @store.get_user(who)
          rec['ignored']
        else
          nil
        end
      end

      #
      # Is the given Jabber registered?
      #
      def registered?(who)
        @store.has_user?(who)
      end

      #
      # Bind the given Jabber user to the given Twitter username and
      # password.
      #
      def register(who, user, pass)
        store = @store

        stoppable_action('twitter_engine_register_user', who, user, pass) do
          store.add_user(who, { 
            'who'         => who.gsub(/\/.*$/, ''),
            'user'        => user,
            'pass'        => pass,
            'updated_at'  => 0,
            'last_id'     => 0,
            'ignored'     => false,
            'sleep_bgn'   => 0, # sleep start time, in hours
            'sleep_end'   => 0, # sleep end time, in hours
          })
        end
      end

      #
      # Forget registration for the given  Jabber user.
      #
      def unregister(who)
        store = @store

        stoppable_action('twitter_engine_unregister_user', who) do
          store.delete_user(who)
        end
      end

      #
      # Send a tweet as the given Jabber user.
      #
      def tweet(who, msg)
        ret, store, fetcher = nil, @store, @fetcher

        stoppable_action('twitter_engine_tweet', who, msg) do
          if user = store.get_user(who)
            ret = fetcher.tweet(user, msg)
          end
        end

        # return result
        ret
      end

      #
      # List recent tweets for the given user.
      #
      def list(who, &block)
        store, fetcher = @store, @fetcher

        stoppable_action('twitter_engine_list', who) do
          if user = store.get_user(who)
            fetcher.get(user, true) do |id, who, time, msg|
              block.call(id, who, time, msg)
            end
          end
        end
      end

      #
      # Update all users.
      #
      def update(&block) 
        store, updates = @store, []

        # make list of updates
        @store.each_user do |user|
          updates << user if needs_update?(user)
        end

        # iterate over updates and do each one
        updates.each do |user|
          stoppable_action('twitter_engine_update', user) do
            update_user(user) do |id, time, src, msg|
              block.call(user['who'], id, time, src, msg)
            end
          end
        end
      end

      private

      #
      # Update specific Jabber user.
      #
      def update_user(user, &block)
        last_id = nil

        @fetcher.get(user) do |id, who, time, msg|
          last_id = id
          block.call(id, who, time, msg)
        end

        @store.update_user(user['who'], {
          'last_id'    => last_id,
          'updated_at' => Time.now.to_i,
        })
      end

      #
      # Does the given Jabber user need an update?
      #
      def needs_update?(user)
        now, since = Time.now, Time.now - @opt['twitter.engine.update_interval']

        # check update interval
        if user['updated_at'].to_i < since.to_i
          # check sleep interval
          !is_sleeping?(user, now)
        else
          # updated within update_interval
          false
        end
      end

      #
      # Is the given Jabber user asleep?
      #
      def is_sleeping?(user, time = Time.now)
        # build sleep range
        sleep = %w{bgn end}.map { |s| user["sleep_#{s}"].to_i }

        # compare user sleep time
        time.hour >= sleep.first && time.hour <= sleep.last
      end

      #
      # Fire a stoppable event.
      #
      def stoppable_action(key, *args, &block)
        if fire("before_#{key}", *args)
          block.call
          fire(key, *args)
        end
      end
    end
  end
end
