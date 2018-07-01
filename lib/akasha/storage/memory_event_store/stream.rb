module Akasha
  module Storage
    class MemoryEventStore
      # Memory-based event stream.
      class Stream
        # Creates a new event stream.
        # Accepts an optional block, allowing for filtering new events and triggering side-effects,
        # before new events are appended to the stream,
        def initialize(&before_write)
          @before_write = before_write || identity
          @events = []
        end

        # Appends events to the stream.
        def write_events(events, revision: nil)
          check_revision!(revision)
          @events += to_recorded_events(@events.size, @before_write.call(events))
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

        private

        def identity
          ->(x) { x }
        end

        def check_revision!(expected_revision)
          return if expected_revision.nil?
          actual_revision = @events.size - 1
          return if expected_revision == actual_revision
          raise ConflictError,
                "Race condition; expected last event version: #{expected_revision} actual: #{actual_revision}"
        end

        def to_recorded_events(current_revision, events)
          events.each_with_index.map do |event, i|
            updated_at = Time.now.utc # Cheating.
            RecordedEvent.new(event.name, event.id, current_revision + i,
                              updated_at, event.metadata, **event.data)
          end
        end
      end
    end
  end
end
