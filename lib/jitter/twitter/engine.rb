require 'net/http'
require 'time'
require 'pablotron/observable'

module Jitter
  module Twitter
    class Engine
      include Pablotron::Observable

      DEFAULTS = {
        # update interval, in minutes
        'twitter.engine.update_interval' => 5,
      }

      def initialize(user_store, fetcher, opt = nil)
        @opt = DEFAULTS.merge(opt || {})
        @store = user_store
        @fetcher = fetcher
      end

      def ignored?(who)
        if rec = @store.get_user(who)
          rec['ignored']
        else
          nil
        end
      end

      def registered?(who)
        @store.has_user?(who)
      end

      def register(who, user, pass)
        store = @store

        stoppable_action('twitter_engine_register_user', who, user, pass) do
          store.add_user(who, { 
            'who'         => who,
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

      def unregister(who)
        store = @store

        stoppable_action('twitter_engine_unregister_user', who) do
          store.delete_user(who)
        end
      end

      def tweet(who, msg)
        store, fetcher = @store, @fetcher

        stoppable_action('twitter_engine_tweet', who, msg) do
          if user = store.get_user(who)
            fetcher.tweet(user, msg)
          end
        end
      end

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

      def is_sleeping?(user, time = Time.now)
        # build sleep range
        sleep = %w{bgn end}.map { |s| user["sleep_#{s}"].to_i }

        # compare user sleep time
        time.hour >= sleep.first && time.hour <= sleep.last
      end

      def stoppable_action(key, *args, &block)
        if fire("before_#{key}", *args)
          block.call
          fire(key, *args)
        end
      end
    end
  end
end
