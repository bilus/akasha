module Akasha
  class CommandRouter
    # Default command transactor providing optional optimistic concurrency.
    # Works by loading aggregate from the repo by id,
    # invoking its method `command`, passing all data,
    # and saving changes to the aggregate in the end.
    class OptimisticTransactor
      # Process a command with a specific aggregate_klass.
      def call(aggregate_klass, command, aggregate_id, options, **data)
        concurrency, revision = parse_options!(options)
        aggregate = aggregate_klass.find_or_create(aggregate_id)
        check_conflict!(aggregate, revision) if concurrency == :optimistic
        aggregate.public_send(command, **data)
        aggregate.save!(concurrency: concurrency)
      end

      private

      def parse_options!(options)
        concurrency = options[:concurrency] || :optimistic
        revision = options[:revision]
        if concurrency == :none && !revision.nil?
          raise ArgumentError, "Unexpected revision #{revision.inspect} when concurrency set to #{concurrency.inspect}"
        end
        [concurrency, revision]
      end

      def check_conflict!(aggregate, revision)
        return if revision.nil? || revision == aggregate.revision
        raise ConflictError, "Conflict detected; expected: #{revision} got: #{aggregate.revision}"
      end
    end
  end
end
