module Akasha
  module Storage
    class HttpEventStore
      # Base class for all HTTP Event store errors.
      Error = Class.new(RuntimeError)

      # Stream name contains invalid characters.
      InvalidStreamNameError = Class.new(Error)

      # Base class for HTTP errors.
      class HttpError < Error
        attr_reader :status_code

        def initialize(status_code)
          @status_code = status_code
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
