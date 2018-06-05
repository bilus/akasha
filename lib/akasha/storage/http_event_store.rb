require_relative 'http_event_store/stream'
require 'http_event_store'

module Akasha
  module Storage
    # HTTP-based interface to Eventstore (https://geteventstore.com)
    class HttpEventStore
      def initialize(host: 'localhost', port: 2113)
        @client = ::HttpEventStore::Connection.new do |config|
          config.endpoint = host
          config.port = port
        end
      end

      def streams
        self # Use the `[]` method on self.
      end

      def [](stream_name)
        Stream.new(@client, stream_name)
      end
    end
  end
end
