module Akasha
  module Storage
    class HttpEventStore
      # HTTP Eventstore stream.
      class Stream
        def initialize(client, stream_name)
          @client = client
          @stream_name = stream_name
        end

        # Appends events to the stream.
        def write_events(events)
          return if events.empty?
          @client.retry_append_to_stream(@stream_name, events)
        end

        # Reads events from the stream starting from `start` inclusive.
        # If block given, reads all events from the position in pages of `page_size`.
        # If block not given, reads `size` events from the position.
        def read_events(start, page_size)
          if block_given?
            position = start
            loop do
              events = read_events(position, page_size)
              return if events.empty?
              yield(events)
              position += events.size
            end
          else
            @client.retry_read_events_forward(@stream_name, start, page_size)
          end
        end
      end
    end
  end
end
