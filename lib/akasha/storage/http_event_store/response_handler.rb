module Akasha
  module Storage
    class HttpEventStore
      # Handles responses from Eventstore HTTP API.
      class ResponseHandler < Faraday::Response::Middleware
        def on_complete(env)
          case env[:status]
          when (400..499)
            raise HttpClientError, env.status
          when (500..599)
            raise HttpServerError, env.status
          end
        end
      end
    end
  end
end
