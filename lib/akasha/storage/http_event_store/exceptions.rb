module Akasha
  module Storage
    class HttpEventStore
      # Base class for all HTTP Event store errors.
      Error = Class.new(RuntimeError)

      # Stream name contains invalid characters.
      InvalidStreamNameError = Class.new(Error)

      # Base class for HTTP errors.
      class HttpError < Error
        attr_reader :status_code, :response_headers

        def initialize(env)
          @status_code = env.status.to_i
          @response_headers = env.response_headers
          super("Unexpected HTTP response: #{@status_code}")
        end
      end

      # 4xx HTTP status code.
      HttpClientError = Class.new(HttpError)

      # 5xx HTTP status code.
      HttpServerError = Class.new(HttpError)
    end
  end
end
