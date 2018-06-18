module Akasha
  module Storage
    class HttpEventStore
      # Manages HTTP ES projections.
      class ProjectionManager
        def initialize(client)
          @client = client
        end

        # Merges all streams into one, filtering the resulting stream
        # so it only contains events with the specified names, using
        # a projection.
        #
        # Arguments:
        #   `name` - name of the projection stream
        #   `event_names` - array of event names
        def merge_all_by_event(name, event_names)
          attempt_create_projection(name, event_names) ||
            update_projection(name, event_names)
        end

        private

        def projection_javascript(name, events)
          callbacks = events.map { |en| "\"#{en}\": function(s,e) { linkTo('#{name}', e) }" }
          # Alternative code using internal indexing.
          # It's broken though because it reorders events for aggregates (because the streams
          # it uses are per-event). An alternative would be to use aggregates as streams
          # to pull from.
          # et_streams = events.map { |en| "\"$et-#{en}\"" }
          # "fromStreams([#{et_streams.join(', ')}]).when({ #{callbacks.join(', ')} });"
          ''"
          // This is hard to find, so I'm leaving it here:
          // options({
          //   reorderEvents: true,
          //   processingLag: 100 //time in ms
          // });
          fromAll().when({ #{callbacks.join(', ')} });
          "''
        end

        def attempt_create_projection(name, event_names)
          create_options = {
            name: name,
            emit: :yes,
            checkpoints: :yes,
            enabled: :yes
          }
          query_string = Rack::Utils.build_query(create_options)
          @client.request(:post, "/projections/continuous?#{query_string}",
                          projection_javascript(name, event_names),
                          'Content-Type' => 'application/javascript')
          true
        rescue HttpClientError => e
          return false if e.status_code == 409
          raise
        end

        def update_projection(name, event_names)
          @client.request(:put, "/projection/#{name}/query?emit=yet",
                          projection_javascript(name, event_names),
                          'Content-Type' => 'application/javascript')
        end
      end
    end
  end
end
