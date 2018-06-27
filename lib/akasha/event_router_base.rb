module Akasha
  # Base class for routing events to event listeners.
  class EventRouterBase
    def initialize(routes = {})
      @routes = Hash.new { |hash, key| hash[key] = [] }
      @routes.merge!(routes.map { |command, listeners| [command, Array(listeners)] }.to_h)
    end

    # Registers a new event listener, derived from
    # `Akasha::EventListener`.
    def register_event_listener(event_name, listener)
      @routes[event_name] << listener
    end

    # Routes an event.
    def route(event_name, aggregate_id, **data)
      @routes[event_name].each do |listener|
        listener = listener.new if listener.is_a?(Class)
        begin
          listener.public_send(:"on_#{event_name}", aggregate_id, **data)
        rescue RuntimeError => e
          log "Error handling event #{event_name.inspect}: #{e}"
        end
      end
    end

    protected

    def registered_event_names
      @routes.keys
    end

    private

    def log(msg)
      puts msg
    end
  end
end
