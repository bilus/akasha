require_relative './changeset'

module Akasha
  class Aggregate
    attr_reader :changeset

    def initialize(id)
      @changeset = Changeset.new(id)
    end

    def apply_events(events)
      events.each do |event|
        send(event_handler(event), event.data)
      end
    end

    private

    def event_handler(event)
      :"on_#{event.name}"
    end
  end
end
