require 'joggle/runner/pstore'
require 'joggle/cli/option-parser'

module Joggle
  module CLI
    #
    # Basic command-line interface for Joggle.
    #
    class Runner
      #
      # Create and run a CLI object.
      #
      def self.run(app, args)
        new(app, args).run
      end

      #
      # Create CLI object.
      #
      def initialize(app, args)
        @opt = OptionParser.run(app, args)
      end

      #
      # Run command-line interface.
      #
      def run
        if @opt['cli.daemon']
          pid = Process.fork { 
            Joggle::Runner::PStore.run(opt)
            exit 0;
          }

          # detach from background process
          Process.detach(pid)

          # print process id and exit
          $stderr.puts "Detached from pid #{pid}"
        else
          Joggle::Runner::PStore.run(opt)
        end

        exit 0;
      end
    end
  end
end
