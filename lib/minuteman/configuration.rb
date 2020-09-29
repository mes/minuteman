module Minuteman
  class Configuration
    attr_accessor :redis, :patterns, :prefix, :parallel, :operations_prefix

    def initialize
      @redis = redis
      @prefix = "Minuteman".freeze
      @operations_prefix = "#{@prefix}::Operations:"
      @parallel = false

      @patterns = {
        year:   -> (time) { time.strftime("%Y") },
        month:  -> (time) { time.strftime("%Y-%m") },
        day:    -> (time) { time.strftime("%Y-%m-%d") },
        hour:   -> (time) { time.strftime("%Y-%m-%d %H") },
        minute: -> (time) { time.strftime("%Y-%m-%d %H:%M") },
      }
    end

    def redis=(redis)
      @redis = redis
    end
  end
end
