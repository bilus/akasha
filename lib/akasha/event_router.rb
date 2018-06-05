module Akasha
  # Routes events to event listeners.
  class EventRouter
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

    # Routes an event (an Akasha::Event instance).
    # This is interface allowing  subscription via `Akasha::Repository#subscribe`.
    def call(aggregate_id, event)
      route(event.name, aggregate_id, **event.data)
    end

    private

    def log(msg)
      puts msg
    end
  end
end
