module Akasha
  class CommandRouter
    # Default command transactor providing optional optimistic concurrency.
    # Works by loading aggregate from the repo by id,
    # invoking its method `command`, passing all data,
    # and saving changes to the aggregate in the end.
    class OptimisticTransactor
      # Process a command with a specific aggregate_klass.
      def call(aggregate_klass, command, aggregate_id, options, **data)
        aggregate = aggregate_klass.find_or_create(aggregate_id)
        aggregate.public_send(command, **data)
        aggregate.save!
      end
    end
  end
end
