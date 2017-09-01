require 'minuteman/model'

module Minuteman
  class Counter < ::Ohm::Model
    attribute :type
    attribute :time
    attribute :lazy
    class User < Counter
      attribute :user_id

      def key
        "#{super}:#{user_id}"
      end
    end

    def key
      "#{self.class.name}::#{type}:#{time}"
    end

    def self.find_or_create(*args)
      create(*args)
    end

    def self.create(*args)
      return self.new(*args)
    end

    def incr
      Minuteman.config.redis.call("INCR", key)
    end

    def count
      Minuteman.config.redis.call("GET", key).to_i
    end
  end
end
