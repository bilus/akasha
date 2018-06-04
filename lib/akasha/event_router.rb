module Akasha
  class EventRouter
    def initialize
      @routes = {}
    end

    def register_event_listener(event_name, listener_class)
      @routes[event_name] = listener_class
    end

    def route(event_name, aggregate_id, **data)
      listener_class = @routes[event_name]
      return if listener_class.nil?
      listener_class.new.public_send(:"on_#{event_name}", aggregate_id, **data)
    end
  end
end
