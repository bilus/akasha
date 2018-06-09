require_relative 'event_router_base'

module Akasha
  class AsyncEventRouter < EventRouterBase
    def initialize(cursor_strategy); end

    def connect!(repository)
      # TODO: Set up projection.
    end

    def run_forever
      # TODO: Loop stream and route each event.
      #       Use cursor strategy.
    end
  end
end
