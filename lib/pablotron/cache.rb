require 'pp' # debug
require 'cgi'
require 'open-uri'
require 'pablotron/observable'

module Pablotron
  class Cache
    include Pablotron::Observable

    DEFAULTS = {
      'user-agent' => "Pablotron-Cacher/0.0.0",
    }

    def initialize(cache_store, extra_headers = nil)
      @extras = extra_headers
      @store = cache_store
    end

    def self.urlify(base, args = nil, hash = nil)
      ret = base

      if args && args.size > 0
        ret = base + '?' + args.map { |k, v| 
          [k, v].map { |s| CGI.escape(s.to_s) }.join('=') 
        }.join('&')
      end

      if hash
        ret << '#' + hash
      end
      
      # return result
      ret
    end

    # delimiter for appending header string to url
    # (chosen because it won't appear in a valid url)
    HEADER_DELIM = '://?&#'

    def url_key(url, headers = nil)
      ret = url

      # append header fragment
      if headers && headers.size > 0
        # sort, concatenate, and append headers to url
        ret += HEADER_DELIM + headers.keys.map { |key| 
          key.downcase 
        }.sort.map { |k| 
          "#{k}:#{headers[k]}" 
        }.join(',')
      end

      # return results
      ret
    end

    def get(url, headers = nil)
      ret = nil

      # create store key
      key = url_key(url, headers)

      # build headers
      opt = expand_headers(headers)

      # if we have an existing cache entry for this url,
      # then use the last-modified and etag headers
      if entry = @store.get_cached(key)
        opt.update({
          'if-modified-since' => entry['last'].to_s,
          'if-none-match'     => entry['etag'],
        })
      end

      # fetch url and handle result
      begin 
        open(url, opt) do |fh|
          ret  = fh.read

          # update store
          @store.add_cached(key, {
            'last'  => fh.last_modified.to_s || fh.meta['date'],
            'etag'  => fh.meta['etag'],
            'data'  => ret.to_s.dup,
          })

          fire('cache_updated', url, ret)
        end
      rescue OpenURI::HTTPError => err
        case err.io.status.first
        when  /^304/
          # not modified
          ret = entry['data'] 
          fire('cache_not_modified', url)
        else
          # unknown status code
          fire('cache_http_error', url, err.io.status.first, err.io.status.last)
        end
      end

      # return result
      ret
    end

    def has?(url, headers = nil)
      key = url_key(url, headers)
      @store.has_cached?(key)
    end

    def delete(url, headers = nil)
      key = url_key(url, headers)
      @store.delete_cached(key)
    end

    private

    def expand_headers(headers = nil)
      [DEFAULTS, @extras, headers].inject({}) do |ret, hash|
        if hash && hash.size > 0
          hash.keys.each do |key|
            ret[key.downcase] = hash[key]
          end
        end

        ret
      end
    end
  end
end
