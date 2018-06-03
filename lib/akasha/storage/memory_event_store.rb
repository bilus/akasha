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
        @streams = Hash.new { |streams, name| streams[name] = Stream.new }
      end
    end
  end
end
