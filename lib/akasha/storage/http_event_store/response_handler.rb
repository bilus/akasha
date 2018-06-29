module Akasha
  module Storage
    class HttpEventStore
      # Handles responses from Eventstore HTTP API.
      class ResponseHandler < Faraday::Response::Middleware
        def on_complete(env)
          case env.status
          when (400..499)
            raise HttpClientError, env
          when (500..599)
            raise HttpServerError, env
          end
        end
      end
    end
  end
end
