module Joggle
  module ConfigParser
    def self.run(path, &block)
      new(path).run(&block)
    end

    def initialize(path)
      @path = path
    end

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
