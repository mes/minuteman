module Minuteman
  class ScopedModel
    attr_accessor :id
    def initialize(id)
      @id = id
    end

    def self.[](id)
      new(id)
    end

    def self.create(scope)
      id = Minuteman.next_id_for(scope)
      new(id)
    end
  end
end
