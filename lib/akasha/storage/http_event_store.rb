require_relative 'http_event_store/client'
require_relative 'http_event_store/stream'

module Akasha
  module Storage
    # HTTP-based interface to Eventstore (https://geteventstore.com)
    class HttpEventStore
      # Base class for all HTTP Event store errors.
      Error = Class.new(RuntimeError)
      # Stream name contains invalid characters.
      InvalidStreamNameError = Class.new(Error)

      # Base class for HTTP errors.
      class HttpError < Error
        attr_reader :status_code

        def initialize(status_code)
          @status_code = status_code
          super("Unexpected HTTP response: #{@status_code}")
        end
      end

      # 4xx HTTP status code.
      HttpClientError = Class.new(HttpError)
      # 5xx HTTP status code.
      HttpServerError = Class.new(HttpError)

      # Creates a new event store client, connecting to the specified host and port
      # using an optional username and password.
      def initialize(host: 'localhost', port: 2113, username: nil, password: nil)
        @client = Client.new(host: host, port: port, username: username, password: password)
      end

      # Returns a Hash of streams. You can retrieve a Stream instance corresponding
      # to any stream by its name. The stream does not have to exist, appending to
      # it will create it.
      def streams
        self # Use the `[]` method on self.
      end

      # Shortcut for accessing streams by their names.
      def [](stream_name)
        Stream.new(@client, stream_name)
      end

      # Merges all streams into one, filtering the resulting stream
      # so it only contains events with the specified names, using
      # a projection.
      #
      # Arguments:
      #   `into` - name of the new stream
      #   `only` - array of event names
      #   `namespace` - optional namespace; if provided, the resulting stream will
      #                 only contain events with the same metadata.namespace
      def merge_all_by_event(into:, only:, namespace: nil)
        @client.merge_all_by_event(into, only, namespace: namespace)
      end
    end
  end
end
