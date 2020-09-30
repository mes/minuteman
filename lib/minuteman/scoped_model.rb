module Minuteman
  class ScopedModel
    attr_accessor :id
    def initialize(scope)
      @id = Minuteman.next_id_for(scope)
      @scope = scope
    end

    def key
      "Minuteman::User:#{@id}"
    end

    def self.[](id)
      new(id)
    end

    def self.create(scope)
      new(scope)
    end
  end
end
