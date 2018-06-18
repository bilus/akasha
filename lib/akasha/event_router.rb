require_relative 'event_router_base'

module Akasha
  # Routes events synchronously, providing consistency.
  # Useful for routing to materializers, providing read-your-writes
  # guarantee.
  class EventRouter < EventRouterBase
    # Connects to the repository.
    def connect!(repository)
      repository.subscribe do |aggregate_id, event|
        route(event.name, aggregate_id, **event.data)
      end
    end
  end
end
