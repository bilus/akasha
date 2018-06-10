require 'corefines/hash'
require 'json'
require 'faraday'
require 'faraday_middleware'
require 'retries'
require 'time'
require 'typhoeus/adapters/faraday'

require_relative 'response_handler'
require_relative 'event_serializer'

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

        # Creates a new client for the host and port with optional username and password
        # for authenticating certain requests.
        def initialize(host: 'localhost', port: 2113, username: nil, password: nil)
          @username = username
          @password = password
          @conn = connection(host, port)
          @serializer = EventSerializer.new
        end

        # Append events to stream, idempotently retrying up to `max_retries`
        def retry_append_to_stream(stream_name, events, expected_version = nil, max_retries: 0)
          retrying(max_retries) do
            append_to_stream(stream_name, events, expected_version)
          end
        end

        # Read events from stream, retrying up to `max_retries` in case of network failures.
        # Reads `count` events starting from `start` inclusive.
        # Can long-poll for events if `poll` is specified.`
        def retry_read_events_forward(stream_name, start, count, poll = 0, max_retries: 0)
          retrying(max_retries) do
            safe_read_events(stream_name, start, count, poll)
          end
        end

        # Issue a generic request against the API.
        def request(method, url, body, headers = {})
          @conn.client.make_request(method, url, body, auth_headers.merge(headers))
        end

        private

        def connection(host, port)
          Faraday.new do |conn|
            conn.host = host
            conn.port = port
            conn.response :json, content_type: 'application/json'
            conn.use ResponseHandler
            conn.adapter :typhoeus
          end
        end

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

        def append_to_stream(stream_name, events, _expected_version = nil)
          @conn.post("/streams/#{stream_name}") do |req|
            req.headers = {
              'Content-Type' => 'application/vnd.eventstore.events+json',
              # 'ES-ExpectedVersion' => expected_version
            }
            req.body = to_event_data(events).to_json
          end
        end

        def safe_read_events(stream_name, start, count, poll)
          resp = @conn.get("/streams/#{stream_name}/#{start}/forward/#{count}") do |req|
            req.headers = {
              'Accept' => 'application/json'
            }
            req.headers['ES-LongPoll'] = poll if poll&.positive?
            req.params['embed'] = 'body'
          end
          event_data = resp.body['entries']
          to_events(event_data)
        rescue HttpClientError => e
          return [] if e.status_code == 404
          raise
        rescue URI::InvalidURIError
          raise InvalidStreamNameError, "Invalid stream name: #{stream_name}"
        end

        def to_event_data(events)
          @serializer.serialize(events)
        end

        def to_events(es_events)
          es_events = es_events.map do |ev|
            ev['data'] &&= JSON.parse(ev['data'])
            ev['metaData'] &&= JSON.parse(ev['metaData'])
            ev
          end
          @serializer.deserialize(es_events)
        end
      end
    end
  end
end
