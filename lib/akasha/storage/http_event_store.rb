require_relative 'http_event_store/client'
require_relative 'http_event_store/stream'

module Akasha
  module Storage
    # HTTP-based interface to Eventstore (https://geteventstore.com)
    class HttpEventStore
      Error = Class.new(RuntimeError)
      InvalidStreamNameError = Class.new(Error)

      def initialize(host: 'localhost', port: 2113, username: nil, password: nil)
        @client = Client.new(host: host, port: port, username: username, password: password)
      end

      def streams
        self # Use the `[]` method on self.
      end

      def [](stream_name)
        Stream.new(@client, stream_name)
      end

      # Merges all streams into one, filtering the resulting stream
      # so it only contains events with the specified names, using
      # a projection.
      #
      # Arguments:
      #   `new_stream_name` - name of the new stream
      #   `only` - array of event names
      def merge_all_by_event(into:, only:)
      end
    end
  end
end
