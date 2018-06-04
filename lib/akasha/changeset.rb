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
    def append(event_name, **data)
      @events << Akasha::Event.new(event_name, **data)
    end
  end
end
