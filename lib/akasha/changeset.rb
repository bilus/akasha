module Akasha
  # Represents changes to an aggregate, for example an array of
  # events generated when handling a command.
  class Changeset
    attr_reader :aggregate_id, :events

    def initialize(aggregate_id)
      @aggregate_id = aggregate_id
      @events = []
    end

    # Adds an event to the changeset.
    def <<(event)
      @events << event
    end

    # Returns true if no changes recorded.
    def empty?
      @events.empty?
    end

    # Clears the changeset.
    def clear!
      @events = []
    end
  end
end
