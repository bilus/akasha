require 'corefines/hash'
require 'json'
require 'faraday'
require 'faraday_middleware'
require 'retries'
require 'time'
require 'typhoeus/adapters/faraday'

require_relative 'response_handler'

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
          @conn = Faraday.new do |conn|
            conn.host = host
            conn.port = port
            conn.response :json, content_type: 'application/json'
            conn.use ResponseHandler
            conn.adapter :typhoeus
          end
        end

        def retry_append_to_stream(stream_name, events, _expected_version = nil, max_retries: 0)
          retrying(max_retries) do
            @conn.post("/streams/#{stream_name}") do |req|
              req.headers = {
                'Content-Type' => 'application/vnd.eventstore.events+json',
                # 'ES-ExpectedVersion' => expected_version
              }
              req.body = to_event_data(events).to_json
            end
          end
        end

        def retry_read_events_forward(stream_name, start, count, poll = 0, max_retries: 0)
          retrying(max_retries) do
            safe_read_events(stream_name, start, count, poll)
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
          events.map do |event|
            base = {
              eventType: event.name,
              data: event.data,
              metadata: event.metadata
            }
            base[:eventId] = event.id unless event.id.nil?
            base
          end
        end

        def to_events(es_events)
          es_events.map do |ev|
            # TODO: Metadata.
            raw_data = ev['data']
            data = JSON.parse(raw_data).symbolize_keys if raw_data
            Akasha::Event.new(ev['eventType'].to_sym, ev['eventId'], Time.iso8601(ev['updated']), **data)
          end
        end
      end
    end
  end
end
