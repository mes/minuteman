require 'ohm'
require 'securerandom'

module Minuteman
  class User < ::Ohm::Model
    attribute :uid

    unique :uid

    def save
      self.uid ||= SecureRandom.uuid
      super
    end

    def track(action, time = Time.now.utc, times = Minuteman.time_spans)
      Minuteman.track(action, self, time, times)
    end

    def add(action, time = Time.now.utc, times = Minuteman.time_spans)
      Minuteman.add(action, time, self, times)
    end

    def count(action, time = Time.now.utc)
      Minuteman::Analyzer.new(action, Minuteman::Counter::User, self)
    end

    def anonymous?
      true
    end

    def self.[](identifier_or_uuid)
      with(:uid, identifier_or_uuid)
    end
  end
end
