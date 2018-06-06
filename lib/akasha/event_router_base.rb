module Akasha
  # Base class for routing events to event listeners.
  class EventRouterBase
    def initialize
      @routes = Hash.new { |hash, key| hash[key] = [] }
    end

    # Registers a new event listener, derived from
    # `Akasha::EventListener`.
    def register_event_listener(event_name, listener_class)
      @routes[event_name] << listener_class
    end

    # Routes an event.
    def route(event_name, aggregate_id, **data)
      @routes[event_name].each do |listener_class|
        listener = listener_class.new
        begin
          listener.public_send(:"on_#{event_name}", aggregate_id, **data)
        rescue RuntimeError => e
          log "Error handling event #{event_name.inspect}: #{e}"
        end
      end
    end

    private

    def log(msg)
      puts msg
    end
  end
end
