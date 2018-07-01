require_relative 'command_router/optimistic_transactor'
require 'corefines/hash'

module Akasha
  # Routes commands to their handlers.
  class CommandRouter
    using Corefines::Hash

    def initialize(**routes)
      @routes = routes
    end

    # Registers a handler.
    #
    # As a result, when `#route!` is called for that command, the aggregate will be
    # loaded from repository, the command will be sent to the object to invoke the
    # object's method, and finally the aggregate will be saved.
    def register(command, aggregate_class = nil, &block)
      raise ArgumentError, 'Pass either aggregate class or block' if aggregate_class && block
      handler = aggregate_class || block
      @routes[command] = handler
    end

    # Routes a command to the registered target.
    # Raises `NotFoundError` if no corresponding target can be found.
    #
    # Arguments:
    #   - command - name of the command
    #   - aggregate_id - aggregate id
    #   - options - flags:
    #     - transactor - transactor instance to replace the default one (`OptimisticTransactor`);
    #   See docs for `OptimisticTransactor` for a list of additional supported options.
    def route!(command, aggregate_id, options = {}, **data)
      handler = @routes[command]
      case handler
      when Class
        transactor = options.fetch(:transactor, default_transactor)
        transactor.call(handler, command, aggregate_id, options, **data)
      when handler.respond_to?(:call)
        handler.call(command, aggregate_id, options, **data)
      when Proc
        handler.call(command, aggregate_id, options, **data)
      when nil
        raise HandlerNotFoundError, "Handler for command #{command.inspect} not found"
      else
        raise UnsupportedHandlerError, "Unsupported command handler #{handler.inspect}"
      end
    end

    private

    def default_transactor
      OptimisticTransactor.new
    end
  end
end
