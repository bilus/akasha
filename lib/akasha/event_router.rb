module Akasha
  # Routes events to event listeners.
  class EventRouter
    def initialize
      @routes = {}
    end

    # Registers a new event listener, derived from
    # `Akasha::EventListener`.
    def register_event_listener(event_name, listener_class)
      @routes[event_name] = listener_class
    end

    # Routes an event.
    def route(event_name, aggregate_id, **data)
      listener_class = @routes[event_name]
      return if listener_class.nil?
      listener_class.new.public_send(:"on_#{event_name}", aggregate_id, **data)
    end

    # Routes an event (an Akasha::Event instance).
    # This is interface allowing  subscription via `Akasha::Repository#subscribe`.
    def call(aggregate_id, event)
      route(event.name, aggregate_id, **event.data)
    end
  end
end
