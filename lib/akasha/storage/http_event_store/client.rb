require 'corefines/hash'
require 'http_event_store'
require 'retries'
require 'typhoeus/adapters/faraday'

module Akasha
  module Storage
    class HttpEventStore
      # Eventstore HTTP client.
      class Client
        using Corefines::Hash

        # Errors to catch and retry request
        RECOVERABLE_ERRORS = [Faraday::TimeoutError, Faraday::ConnectionFailed].freeze
        # A lower limit for the interval.
        MIN_INTERVAL = 0
        # An upper limit for the interval.
        MAX_INTERVAL = 10.0

        def initialize(host: 'localhost', port: 2113, username: nil, password: nil)
          @username = username
          @password = password
          @conn = ::HttpEventStore::Connection.new do |config|
            config.endpoint = host
            config.port = port
            # config.http_adapter = :typhoeus
          end
        end

        def retry_append_to_stream(stream_name, events, expected_version = nil, max_retries: 0)
          retrying(max_retries) do
            @conn.append_to_stream(stream_name, to_event_data(events), expected_version)
          end
        end

        def retry_read_events_forward(stream_name, start, count, pool = 0, max_retries: 0)
          retrying(max_retries) do
            to_events(safe_read_events(stream_name, start, count, pool))
          end
        end

        def request(method, url, body, headers = {})
          @conn.client.make_request(method, url, body, auth_headers.merge(headers))
        end

        private

        def auth_headers
          if @username && @password
            auth = Base64.urlsafe_encode64([@username, @password].join(':'))
            {
              'Authorization' => "Basic #{auth}"
            }
          else
            {}
          end
        end

        def retrying(max_retries)
          with_retries(base_sleep_seconds: MIN_INTERVAL, max_sleep_seconds: MAX_INTERVAL,
                       max_tries: 1 + max_retries, rescue: RECOVERABLE_ERRORS) do
            yield
          end
        end

        def safe_read_events(stream_name, start, count, pool)
          @conn.read_events_forward(stream_name, start, count, pool)
        rescue ::HttpEventStore::StreamNotFound
          []
        rescue URI::InvalidURIError
          raise InvalidStreamNameError, "Invalid stream name: #{stream_name}"
        end


        def to_event_data(events)
          events.map do |event|
            {
              event_type: event.name,
              data: event.data,
              metadata: event.metadata
            }
          end
        end

        def to_events(es_events)
          es_events.map do |ev|
            Akasha::Event.new(ev.type.to_sym, ev.event_id, ev.created_time, **ev.data.symbolize_keys)
          end
        end
      end
    end
  end
end
