module Minuteman
  class Counter
    attr_accessor :type
    attr_accessor :time
    attr_accessor :lazy

    class User < Counter
      attr_accessor :user_id
      def initialize(type:, time: nil, lazy: false, user_id:)
        super(type: type, time: time, lazy: lazy)
        @user_id = user_id
      end

      def key
        "#{super}:#{@user_id}"
      end
    end
    def initialize(type:, time: nil, lazy: false)
      @type = type
      @time = time
      @lazy = lazy
    end

    def key
      "#{self.class.name}::#{@type}:#{@time}"
    end

    def self.find_or_create(*args)
      create(*args)
    end

    def self.create(*args)
      return self.new(*args)
    end

    def incr(amount = 1)
      Minuteman.config.redis.call("INCRBY", key, amount)
    end

    def count
      Minuteman.config.redis.call("GET", key).to_i
    end
  end
end
