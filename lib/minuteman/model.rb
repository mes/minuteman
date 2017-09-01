require 'ohm'

module Minuteman
  class Model

    def initialize(*args)
      @time = args.first[:time]
      @type = args.first[:type]
    end

    def self.find(*args)
      looked_up = "#{self.name}::#{args.first[:type]}:#{args.first[:time]}:id"
      potential_id = Minuteman.config.redis.call("GET", looked_up)

      return nil if !potential_id

      event = self[potential_id]
      event.type = args.first[:type]
      event.time = args.first[:time]

      event
    end

    def self.find_or_create(*args)
      find(*args) || create(*args)
    end

    def self.create(*args)
      if !args[0][:lazy]
        event = self.new(*args)

        return event
      else
        return self.new(*args)
      end
    end

    def key
      "#{self.class.name}::#{@type}:#{@time}"
    end

  end
end
