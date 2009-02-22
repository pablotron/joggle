module Joggle
  #
  # Simple configuration file parser.
  #
  module ConfigParser
    #
    # Parse configuration file and pass each directive to the
    # specified block.
    #
    def self.run(path, &block)
      new(path).run(&block)
    end

    #
    # Create a new config file parser.
    #
    def initialize(path)
      @path = path
    end

    #
    # Parse configuration file and pass each directive to the specified
    # block.
    #
    def run(&block)
      File.readlines(@path).each do |line|
        next if line =~ /\s*#/ || line !~ /\S/
        line = line.strip
        key, val = line.split(/\s+/, 2)

        if key && key.size > 0
          block.call(key, val)
        end
      end
    end
  end
end
