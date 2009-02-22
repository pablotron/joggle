require 'optparse'
require 'joggle/version'
require 'joggle/config-parser'
require 'joggle/cli/option-parser'

module Joggle
  module CLI
    # 
    # Option parser for Joggle command-line interface.
    # 
    class OptionParser
      # 
      # Default configuration.
      # 
      DEFAULTS = {
        # pull default jabber username and password from environment
        'runner.client.user' => ENV['JOGGLE_USERNAME'],
        'runner.client.pass' => ENV['JOGGLE_PASSWORD'],
      }

      # 
      # Create and run a new command-line option parser.
      # 
      def self.run(app, args)
        new(app).run(args)
      end

      # 
      # Create new command-line option parser.
      # 
      def initialize(app)
        @app = app
      end

      # 
      # Run command-line option parser.
      # 
      def run(args)
        ret = DEFAULTS.merge({})

        # create option parser
        o = ::OptionParser.new do |o|
          o.banner = "Usage: #@app [options]"
          o.separator " "

          # add command-line options
          o.separator "Options:"

          o.on('-c', '--config FILE', 'Use configuration file FILE.') do |v|
            Joggle::ConfigParser.run(v) do |key, val|
              if key == 'engine.allow'
                add_allowed(ret, val)
              elsif key == 'engine.update.range'
                add_update_range(ret, val)
              else
                ret[key] = val
              end
            end
          end

          o.on('-A', '--allow USER', 'Allow Jabber subscription from USER.') do |v|
            add_allowed(ret, v)
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

          o.on('-l', '--log FILE', 'Log to FILE.') do |v|
            ret['runner.log.path'] = v
          end

          o.on('-p', '--password PASS', 'Jabber password (INSECURE!).') do |v|
            ret['runner.client.pass'] = v
          end

          o.on('-s', '--store FILE', 'Use FILE as backing store.') do |v|
            ret['runner.store.path'] = v
          end

          o.on('-u', '--username USER', 'Jabber username.') do |v|
            ret['runner.client.user'] = v
          end

          o.separator ' '

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

      #
      # Add an allowed user.
      #
      def add_allowed(ret, val)
        return unless val && val =~ /\S/

        ret['engine.allow'] ||= []
        ret['engine.allow'].concat(val.strip.downcase.split(/\s*,\s*/))
      end

      def add_update_range(ret, val)
        return unless val && val =~ /\S/

        if md = val.match(/(\d+)\s*-\s*(\d+)\s+(\d+)/)
          key, mins = "#{md[1]}-#{md[2]}", md[3].to_i
          ret['engine.update.range'] ||= {}
          ret['engine.update.range'][key] = mins
        end
      end
    end
  end
end
