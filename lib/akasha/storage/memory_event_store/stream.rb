module Akasha
  module Storage
    class MemoryEventStore
      # Memory-based event stream.
      class Stream
        def initialize
          @events = []
        end

        # Appends events to the stream.
        def write_events(events)
          @events += events
        end

        # Reads events from the stream starting from `position` inclusive.
        # If block given, reads all events from the position in chunks
        # of `size`.
        # If block not given, reads `size` events from the position.
        def read_events(position, size, &block)
          if block_given?
            @events.lazy.drop(position).each_slice(size, &block)
          else
            @events[position..position + size]
          end
        end
      end
    end
  end
end
