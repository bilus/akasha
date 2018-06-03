module Akasha
  class Changeset
    attr_reader :aggregate_id, :events

    def initialize(aggregate_id)
      @aggregate_id = aggregate_id
      @events = []
    end

    def <<(event)
      @events << event
    end
  end
end
