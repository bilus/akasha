module Akasha
  # Represents changes to an aggregate, for example an array of
  # events generated when handling a command.
  class Changeset
    attr_reader :events

    def initialize(aggregate)
      @aggregate = aggregate
      @events = []
    end

    def aggregate_id
      @aggregate.id
    end

    # Adds an event to the changeset.
    def append(event_name, **data)
      id = SecureRandom.uuid
      event = Akasha::Event.new(event_name, id, { aggregate_id: aggregate_id }, **data)
      @aggregate.apply_events([event])
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
