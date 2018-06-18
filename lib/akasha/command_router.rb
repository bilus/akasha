require_relative 'command_router/default_handler'
require 'corefines/hash'

module Akasha
  # Routes commands to their handlers.
  class CommandRouter
    using Corefines::Hash

    # Raised when no corresponding target can be found for a command.
    NotFoundError = Class.new(RuntimeError)

    def initialize(routes = {})
      @routes = routes.flat_map do |command, target|
        if target.is_a?(Class)
          { command => DefaultHandler.new(target) }
        else
          { command => target }
        end
      end
    end

    # Registers a custom route, specifying either a lambda or a block.
    # If both lambda and block are specified, lambda takes precedence.
    def register_route(command, lambda = nil, &block)
      callable = lambda || block
      @routes[command] = callable
    end

    # Registers a default route, mapping a command to an aggregate class.
    # As a result, when `#route!` is called for that command, the aggregate
    # will be loaded from repository, the command will be sent to the object
    # to invoke the object's method, and finally the aggregate will be saved.
    def register_default_route(command, aggregate_class)
      register_route(command, DefaultHandler.new(aggregate_class))
    end

    # Routes a command to the registered target.
    # Raises NotFoundError if no corresponding target can be found.
    def route!(command, aggregate_id, **data)
      handler = @routes[command]
      return handler.call(command, aggregate_id, **data) if handler
      raise NotFoundError, "Target for command #{command.inspect} not found"
    end
  end
end
