require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'pablotron/cache'

module Joggle
  module Twitter
    #
    # Handler for Twitter HTTP requests.
    #
    class Fetcher
      DEFAULTS = {
        'twitter.fetcher.url.timeline' => 'https://twitter.com/statuses/friends_timeline.json',
        'twitter.fetcher.url.tweet'    => 'https://twitter.com/statuses/update.json',
      }

      #
      # Create a new Twitter::Fetcher object.
      #
      def initialize(message_store, cache, opt = {})
        @opt = DEFAULTS.merge(opt || {})
        @store = message_store
        @cache = cache
      end

      #
      # Get Twitter updates for given user and pass them to the
      # specified block.
      #
      def get(user, show_all = false, &block)
        url, opt = url_for(user, 'timeline'), opt_for(user)

        if data = @cache.get(url, opt)
          JSON.parse(data).reverse.each do |row|
            cached = @store.has_message?(row['id'])

            if show_all || !cached
              # cache message
              @store.add_message(row['id'], row)

              # send to parent
              block.call(
                row['id'], 
                Time.parse(row['created_at']), 
                row['user']['screen_name'], 
                row['text']
              )
            end
          end
        end
      end

      #
      # Send a tweet.  Use Joggle::Engine#tweet instead.
      #
      def tweet(user, msg)
        # build URI and headers (opt)
        url, opt = url_for(user, 'tweet'), opt_for(user)
        uri = URI.parse(url)
        ret = nil

        # build post data
        data = {
          'status' => msg,
        }.map { |a| 
          a.map { |v| CGI.escape(v) }.join('=') 
        }.join('&')

        # FIXME: add user-agent to headers
        req = Net::HTTP.new(uri.host, uri.port)
        req.use_ssl = (uri.scheme == 'https')

        # start http request
        req.start do |http|
          # post request
          r = http.post(uri.path, data, opt)

          # check response
          case r
          when Net::HTTPSuccess
            ret = JSON.parse(r.body)

            # File.open('/tmp/foo.log', 'a') do |fh|
            #   fh.puts "r.body = #{r.body}"
            # end

            # check result
            if ret && ret.key?('id')
              @store.add_message(ret['id'], ret)
            else
              throw "got weird response from twitter"
            end
          else
            throw r
          end
        end

        # return result
        ret
      end

      private

      def url_for(user, key)
        args = nil

        if false && key == 'timeline'
          if user['last_id'] && user['last_id'] > 0
            args = { 'since_id' => user['last_id'] }
          end
        end

        Pablotron::Cache.urlify(@opt['twitter.fetcher.url.' + key], args)
      end

      def opt_for(user)
        str = ["#{user['user']}:#{user['pass']}"].pack('m').strip
        { 'Authorization' => 'Basic ' + str }
      end
    end
  end
end
