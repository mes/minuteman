require 'ohm'
require 'securerandom'
require 'minuteman/scoped_model'

module Minuteman
  class User < ScopedModel

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
  end
end
