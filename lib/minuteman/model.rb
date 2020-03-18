module Minuteman
  class Model

    def initialize(*args)
      @time = args.first[:time]
      @type = args.first[:type]
    end

    def self.find_or_create(*args)
      create(*args)
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
