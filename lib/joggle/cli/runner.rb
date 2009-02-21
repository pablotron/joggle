require 'joggle/runner/pstore'
require 'joggle/cli/option-parser'

module Joggle
  module CLI
    class Runner
      def self.run(args)
        new(args).run
      end

      def initialize(args)
        @opt = OptionParser.run(args)
      end

      def run
        Joggle::Runner.run(opt)
      end
    end
  end
end
