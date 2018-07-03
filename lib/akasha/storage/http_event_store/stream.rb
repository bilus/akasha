module Akasha
  module Storage
    class HttpEventStore
      # HTTP Eventstore stream.
      class Stream
        attr_reader :name

        # Create a stream object for accessing a ES stream.
        # Does not create the underlying stream itself.
        # Use the `max_retries` option to choose how many times to retry in case
        # of network failures.
        def initialize(client, stream_name, max_retries: 0)
          @client = client
          @name = stream_name
          @max_retries = max_retries
        end

        # Appends `events` to the stream.
        # You can specify `revision` to use optimistic concurrency control:
        #    - nil  - just append, no concurrency control,
        #    - -1   - the stream doesn't exist,
        #    - >= 0 - expected revision of the last event in stream.
        def write_events(events, revision: nil)
          return if events.empty?
          expected_version = revision.nil? ? -2 : revision
          @client.retry_append_to_stream(@name, events, expected_version, max_retries: @max_retries)
        end

        # Reads events from the stream starting from `start` inclusive.
        # If block given, reads all events from the position in pages of `page_size`.
        # If block not given, reads `size` events from the position.
        # You can also turn on long-polling using `poll` and setting it to the number
        # of seconds to wait for.
        def read_events(start, page_size, poll: 0)
          if block_given?
            position = start
            loop do
              events = read_events(position, page_size, poll: poll)
              return if events.empty?
              yield(events)
              position += events.size
            end
          else
            @client.retry_read_events_forward(@name, start, page_size, poll, max_retries: @max_retries)
          end
        end

        # Reads stream metadata.
        def metadata
          @client.retry_read_metadata(@name, max_retries: @max_retries)
        end

        # Updates stream metadata.
        def metadata=(metadata)
          @client.retry_write_metadata(@name, metadata, max_retries: @max_retries)
        end
      end
    end
  end
end
