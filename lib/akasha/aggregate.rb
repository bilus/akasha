require_relative './changeset'

module Akasha
  module SyntaxHelpers
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def connect!(repository)
        @@repository = repository
      end

      def repository
        @@repository
      end

      def find_or_create(id)
        @@repository.load_aggregate(self, id)
      end
    end

    module InstanceMethods
      def save!
        self.class.repository.save_aggregate(self)
      end
    end
  end

  class Aggregate
    include SyntaxHelpers

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
