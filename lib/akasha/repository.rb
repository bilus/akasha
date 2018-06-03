module Akasha
  class Repository
    STREAM_NAME_SEP = '-'.freeze

    def initialize(store)
      @store = store
    end

    def load_aggregate(klass, id)
      agg = klass.new(id)

      start = 0
      chunk_size = 100
      stream(klass, id).read_events(start, chunk_size) do |events|
        agg.apply_events(events)
      end

      agg
    end

    def save_aggregate(aggregate)
      changeset = aggregate.changeset
      stream(aggregate.class, changeset.aggregate_id).write_events(changeset.events)
    end

    private

    def stream_name(aggregate_klass, aggregate_id)
      "#{aggregate_klass}#{STREAM_NAME_SEP}#{aggregate_id}"
    end

    def stream(aggregate_klass, aggregate_id)
      @store.streams[stream_name(aggregate_klass, aggregate_id)]
    end
  end
end
