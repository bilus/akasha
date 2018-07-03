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
        #   `namespace` - optional namespace; if provided, the resulting stream will
        #                 only contain events with the same metadata.namespace
        def merge_all_by_event(name, event_names, namespace: nil)
          attempt_create_projection(name, event_names, namespace) ||
            update_projection(name, event_names, namespace)
        end

        private

        def projection_javascript(name, events, namespace)
          callback_fmt = if namespace.nil?
                           <<~JS
                             '%{en}': function(s, e) {
                               linkTo('%{name}', e)
                             }
                           JS
                         else
                           <<~JS
                             '%{en}': function(s, e) {
                               if (e['metadata'] !== null && e['metadata']['namespace'] === '%{namespace}') {
                                 linkTo('%{name}', e)
                               }
                             }
                           JS
                         end
          callbacks = events.map { |en| format(callback_fmt, en: en, name: name, namespace: namespace) }

          # Alternative code using internal indexing.
          # It's broken though because it reorders events for aggregates (because the streams
          # it uses are per-event). An alternative would be to use aggregates as streams
          # to pull from.
          # et_streams = events.map { |en| "\"$et-#{en}\"" }
          # "fromStreams([#{et_streams.join(', ')}]).when({ #{callbacks.join(', ')} });"
          <<~JS
            // This is hard to find, so I'm leaving it here:
            // options({
            //   reorderEvents: true,
            //   processingLag: 100 //time in ms
            // });
            fromAll().when({
              #{callbacks.join(', ')}
            });
          JS
        end

        def attempt_create_projection(name, event_names, namespace)
          create_options = {
            name: name,
            emit: :yes,
            checkpoints: :yes,
            enabled: :yes
          }
          query_string = Rack::Utils.build_query(create_options)
          @client.request(:post, "/projections/continuous?#{query_string}",
                          projection_javascript(name, event_names, namespace),
                          'Content-Type' => 'application/javascript')
          true
        rescue HttpClientError => e
          return false if e.status_code == 409
          raise
        end

        def update_projection(name, event_names, namespace)
          @client.request(:put, "/projection/#{name}/query?emit=yet",
                          projection_javascript(name, event_names, namespace),
                          'Content-Type' => 'application/javascript')
        end
      end
    end
  end
end
