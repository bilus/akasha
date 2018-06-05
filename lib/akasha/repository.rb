module Akasha
  # Aggregate repository.
  # Not meant to be used directly (see aggregate/syntax_helpers.rb)
  # See specs for usage.
  class Repository
    STREAM_NAME_SEP = '-'.freeze

    # Creates a new repository using the underlying `store` (e.g. `MemoryEventStore`).
    def initialize(store)
      @store = store
      @subscribers = []
    end

    # Loads an aggregate identified by `id` and `klass` from the repository.
    # Returns an aggregate instance of class `klass` constructed by applying events from the corresponding
    # stream.
    def load_aggregate(klass, id)
      agg = klass.new(id)

      start = 0
      page_size = 20
      stream(klass, id).read_events(start, page_size) do |events|
        agg.apply_events(events)
      end

      agg
    end

    # Saves an aggregate to the repository, appending events to the corresponding stream.
    def save_aggregate(aggregate)
      changeset = aggregate.changeset
      stream(aggregate.class, changeset.aggregate_id).write_events(changeset.events)
      notify_subscribers(aggregate)
    end

    # Subscribes to event streams passing either a lambda or a block.
    # Example:
    #
    #   repo.subscribe do |aggregate_id, event|
    #     ... handle the event ...
    #   end
    def subscribe(lambda = nil, &block)
      callable = lambda || block
      @subscribers << callable
    end

    private

    def stream_name(aggregate_klass, aggregate_id)
      "#{aggregate_klass}#{STREAM_NAME_SEP}#{aggregate_id}"
    end

    def stream(aggregate_klass, aggregate_id)
      @store.streams[stream_name(aggregate_klass, aggregate_id)]
    end

    def notify_subscribers(aggregate)
      id = aggregate.changeset.aggregate_id
      events = aggregate.changeset.events
      @subscribers.each do |subscriber|
        events.each do |event|
          subscriber.call(id, event)
        end
      end
    end
  end
end
