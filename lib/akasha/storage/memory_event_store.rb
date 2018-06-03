require_relative 'memory_event_store/stream'

module Akasha
  module Storage
    class MemoryEventStore
      attr_reader :streams

      def initialize
        @streams = Hash.new { |streams, name| streams[name] = Stream.new }
      end
    end
  end
end
