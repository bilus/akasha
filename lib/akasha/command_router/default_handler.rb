module Akasha
  class CommandRouter
    # Default command handler.
    # Works by loading aggregate from the repo by id,
    # invoking its method `command`, passing all data,
    # and saving changes to the aggregate in the end.
    class DefaultHandler
      def initialize(klass)
        @klass = klass
      end

      def call(command, aggregate_id, **data)
        aggregate = @klass.find_or_create(aggregate_id)
        aggregate.public_send(command, **data)
        aggregate.save!
      end
    end
  end
end
