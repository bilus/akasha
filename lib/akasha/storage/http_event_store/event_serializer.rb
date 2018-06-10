require 'corefines/hash'

module Akasha
  module Storage
    class HttpEventStore
      # Serializes and deserializes events to and from the format required
      # by the HTTP Eventstore API
      class EventSerializer
        using Corefines::Hash

        def serialize(events)
          events.map do |event|
            base = {
              'eventType' => event.name,
              'data' => event.data,
              'metaData' => {
                created_at: event.created_at.utc.iso8601
              }
            }
            base['eventId'] = event.id unless event.id.nil?
            base
          end
        end

        def deserialize(es_events)
          es_events.map do |ev|
            metadata = ev['metaData']&.symbolize_keys || {}
            created_at = Time.iso8601(metadata[:created_at]) if metadata[:created_at]
            saved_at = Time.iso8601(ev[:updated]) if ev[:updated]
            data = ev['data']&.symbolize_keys || {}
            Akasha::Event.new(ev['eventType'].to_sym, ev['eventId'], created_at, saved_at, **data)
          end
        end
      end
    end
  end
end
