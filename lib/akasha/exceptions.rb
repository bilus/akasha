module Akasha
  # Base exception class for all Akasha errors.
  Error = Class.new(RuntimeError)

  ## Command routing errors

  # Base exception class for errors related to routing commands.
  CommandRoutingError = Class.new(Error)

  # No corresponding target for a command.
  HandlerNotFoundError = Class.new(CommandRoutingError)

  # Type of the handler found for a command is not supported.
  UnsupportedHandlerError = Class.new(CommandRoutingError)

  ## Concurrency errors

  # Base exception class for concurrency-related errors.
  ConcurrencyError = Class.new(Error)

  # Stale aggregate revision number passed with command.
  # It typically means that another actor already updated the
  # aggregate.
  StaleRevisionError = Class.new(ConcurrencyError)

  # Stream modified while processing a command.
  ConflictError = Class.new(ConcurrencyError)

  # Missing stream when saving checkpoint.
  CheckpointStreamNotFoundError = Class.new(Error)

  ## Storega errors

  # Base class for all storage backend errors.
  StorageError = Class.new(Error)

  # Stream name contains invalid characters.
  InvalidStreamNameError = Class.new(StorageError)

  # Base class for HTTP errors.
  class HttpError < StorageError
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
