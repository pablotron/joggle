require 'optparse'
require 'joggle/version'
require 'joggle/config-parser'
require 'joggle/cli/option-parser'

module Joggle
  module CLI
    class OptionParser
      DEFAULTS = {
        # any option defaults go here
      }

      def self.run(app, args)
        new(app).run(args)
      end

      def initialize(app)
        @app = app
      end

      def run(args)
        ret = DEFAULTS.merge({})

        # create option parser
        o = ::OptionParser.new do |o|
          o.banner = "Usage: #@app [options]"
          o.separator ''

          # add command-line options
          o.separator "Options:"

          o.on('-c', '--config FILE', 'Use configuration file FILE.') do |v|
            Joggle::ConfigParser.run(v).each do |key, val|
              if key == 'engine.allow'
                add_allowed(ret, val)
              else
                ret[key] = val
              end
            end
          end

          o.on('-A', '--allow USER', 'Allow Jabber subscription from USER.') do |v|
            add_allowed(ret, v)
          end

          o.on('-l', '--log FILE', 'Log to FILE.') do |v|
            ret['runner.log.path'] = v
          end

          o.on('-D', '--daemon', 'Run as daemon (in background).') do |v|
            ret['cli.daemon'] = true
          end

          o.on('--foreground', 'Run in foreground (the default).') do |v|
            ret['cli.daemon'] = false
          end

          o.on('-L', '--log-level LEVEL', 'Set log level to LEVEL.') do |v|
            ret['runner.log.level'] = v
          end

          o.on('-p', '--password PASS', 'Jabber password.') do |v|
            ret['runner.client.pass'] = v
          end

          o.on('-p', '--store FILE', 'Use FILE as backing store.') do |v|
            ret['runner.store.path'] = v
          end

          o.on('-u', '--username USER', 'Jabber username.') do |v|
            ret['runner.client.user'] = v
          end

          o.on_tail('-v', '--version', 'Print version string.') do
            puts "Joggle %s, by %s" % [
              Joggle::VERSION,
              'Paul Duncan <pabs@pablotron.org>',
            ]
            exit
          end

          o.on_tail('-h', '--help', 'Print help information.') do
            puts o
            exit
          end
        end

        # parse arguments
        o.parse(args)

        # return results
        ret
      end

      private 

      def add_allowed(ret, val)
        return unless val && val =~ /\S/

        ret['engine.allow'] ||= []
        ret['engine.allow'].concat(val.strip.downcase.split(/\s*,\s*/))
      end
    end
  end
end
