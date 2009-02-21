require 'joggle/runner/pstore'
require 'joggle/cli/option-parser'

module Joggle
  module CLI
    class Runner
      def self.run(args)
        new(args).run
      end

      def initialize(app, args)
        @opt = OptionParser.run(app, args)
      end

      def run
        Joggle::Runner::PStore.run(opt)
      end
    end
  end
end
