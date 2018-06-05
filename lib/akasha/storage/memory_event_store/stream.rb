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

        # Reads events from the stream starting from `start` inclusive.
        # If block given, reads all events from the start in pages of `page_size`.
        # If block not given, reads `page_size` events from the start.
        def read_events(start, page_size, &block)
          if block_given?
            @events.lazy.drop(start).each_slice(page_size, &block)
          else
            @events[start..start + page_size]
          end
        end
      end
    end
  end
end
