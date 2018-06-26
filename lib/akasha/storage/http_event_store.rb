require_relative 'http_event_store/client'
require_relative 'http_event_store/stream'
require_relative 'http_event_store/exceptions'

module Akasha
  module Storage
    # HTTP-based interface to Eventstore (https://geteventstore.com)
    class HttpEventStore
      # Creates a new event store client, connecting to the specified `host` and `port`
      # using an optional `username` and `password`.
      # Use the `max_retries` option to choose how many times to retry in case of network failures.
      def initialize(host: 'localhost', port: 2113, username: nil, password: nil, max_retries: 0)
        @client = Client.new(host: host, port: port, username: username, password: password)
        @max_retries = max_retries
      end

      # Returns a Hash of streams. You can retrieve a Stream instance corresponding
      # to any stream by its name. The stream does not have to exist, appending to
      # it will create it.
      def streams
        self # Use the `[]` method on self.
      end

      # Shortcut for accessing streams by their names.
      def [](stream_name)
        Stream.new(@client, stream_name, max_retries: @max_retries)
      end

      # Merges all streams into one, filtering the resulting stream
      # so it only contains events with the specified names, using
      # a projection.
      #
      # Arguments:
      #   `into` - name of the new stream
      #   `only` - array of event names
      #   `namespace` - optional namespace; if provided, the resulting stream will
      #                 only contain events with the same `metadata[:namespace]`
      def merge_all_by_event(into:, only:, namespace: nil)
        @client.merge_all_by_event(into, only, namespace: namespace, max_retries: @max_retries)
      end
    end
  end
end
