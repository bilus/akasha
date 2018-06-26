require_relative 'memory_event_store/stream'

module Akasha
  module Storage
    # Memory-based event store.
    class MemoryEventStore
      # Access to streams
      # Example:
      #   store.streams['some-stream-name']
      attr_reader :streams

      def initialize
        store = self
        @streams = Hash.new do |streams, name|
          streams[name] = Stream.new do |new_events|
            store.update_projections(new_events)
            new_events
          end
        end
        @projections = []
      end

      # Merges all streams into one, filtering the resulting stream
      # so it only contains events with the specified names.
      #
      # Arguments:
      #   `new_stream_name` - name of the new stream
      #   `only` - array of event names
      #   `namespace` - optional namespace; if provided, the resulting stream will
      #                 only contain events with the same metadata.namespace
      def merge_all_by_event(into:, only:, namespace: nil)
        new_stream = Stream.new do |new_events|
          new_events.select do |event|
            (namespace.nil? || namespace == event.metadata[:namespace]) &&
              only.include?(event.name)
          end
        end
        @streams[into] = new_stream
        @projections << new_stream
        new_stream
      end

      protected

      def update_projections(events)
        @projections.each do |projection|
          projection.write_events(events)
        end
      end
    end
  end
end
