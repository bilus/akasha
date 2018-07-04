module Akasha
  # Aggregate repository.
  # Not meant to be used directly (see aggregate/syntax_helpers.rb)
  # See specs for usage.
  class Repository
    attr_reader :store, :namespace

    STREAM_NAME_SEP = '-'.freeze

    # Creates a new repository using the underlying `store` (e.g. `MemoryEventStore`).
    # - namespace - optional namespace allowing for multiple applications to share the same Eventstore
    #               database without name conflicts
    def initialize(store, namespace: nil)
      @store = store
      @subscribers = []
      @namespace = namespace
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
    def save_aggregate(aggregate, concurrency: :none)
      changeset = aggregate.changeset
      events = changeset.events.map { |event| event.with_metadata(namespace: @namespace) }
      revision = aggregate.revision if concurrency == :optimistic
      stream(aggregate.class, changeset.aggregate_id).write_events(events, revision: revision)
      notify_subscribers(changeset.aggregate_id, events)
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

    # Merges all streams into one, filtering the resulting stream
    # so it only contains events with the specified names, using
    # a projection.
    #
    # Arguments:
    #   `into` - name of the new stream
    #   `only` - array of event names
    def merge_all_by_event(into:, only:)
      @store.merge_all_by_event(into: into, only: only, namespace: @namespace)
    end

    private

    def stream_name(aggregate_klass, aggregate_id)
      parts = []
      parts << @namespace if @namespace
      parts << aggregate_klass
      parts << aggregate_id
      parts.join(STREAM_NAME_SEP)
    end

    def stream(aggregate_klass, aggregate_id)
      @store.streams[stream_name(aggregate_klass, aggregate_id)]
    end

    def notify_subscribers(aggregate_id, events)
      @subscribers.each do |subscriber|
        events.each do |event|
          subscriber.call(aggregate_id, event)
        end
      end
    end
  end
end
