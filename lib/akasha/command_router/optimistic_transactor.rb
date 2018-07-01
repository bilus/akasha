require 'retries'

module Akasha
  class CommandRouter
    # Default command transactor providing optional optimistic concurrency.
    # Works by loading aggregate from the repo by id, having it handle the command,
    # and saving changes to the aggregate to the repository.
    class OptimisticTransactor
      # The default maximum number of retries when conflict is detected.
      MAX_CONFLICT_RETRIES = 2
      # A lower limit for a retry interval.
      MIN_CONFLICT_RETRY_INTERVAL = 0
      # An upper limit for a retry interval.
      MAX_CONFLICT_RETRY_INTERVAL = 1

      # Have an aggregate handle a command.
      # - `aggregate_class` - aggregate class you want to handle the command,
      # - `command` - command the aggregate will process, corresponding to a method of the aggregate class.
      # - `aggregate_id` - id of the aggregate instance the command is for,
      # - `options`:
      #     - concurrency - `:optimistic` or `:none` (default: `:optimistic`);
      #     - revision - set to aggregate revision to detect conflicts while saving
      #       aggregates (requires `concurrency == :optimistic`); `nil` to just save
      #       without concurrency control;
      #     - max_conflict_retries - how many times to retry processing a command if a conflict
      #       is detected (`ConflictError`); default: MAX_CONFLICT_RETRIES;
      #     - min_conflict_retry_interval - minimum time to sleep between retries; default MIN_CO_RETRY_INTERVAL;
      #     - max_conflict_retry_interval - maximum time to sleep between retries; default MIN_CO_RETRY_INTERVAL.
      # - `data`- command payload.
      def call(aggregate_class, command, aggregate_id, options, **data)
        max_conflict_retries = options.fetch(:max_conflict_retries, MAX_CONFLICT_RETRIES)
        min_conflict_retry_interval = options.fetch(:min_conflict_retry_interval, MIN_CONFLICT_RETRY_INTERVAL)
        max_conflict_retry_interval = options.fetch(:max_conflict_retry_interval, MAX_CONFLICT_RETRY_INTERVAL)
        with_retries(base_sleep_seconds: min_conflict_retry_interval, max_sleep_seconds: max_conflict_retry_interval,
                     max_tries: 1 + max_conflict_retries, rescue: [Akasha::ConflictError]) do
          handle_command(aggregate_class, command, aggregate_id, options, **data)
        end
      end

      protected

      def handle_command(aggregate_class, command, aggregate_id, options, **data)
        concurrency, revision = parse_options!(options)
        aggregate = aggregate_class.find_or_create(aggregate_id)
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
        raise StaleRevisionError, "Conflict detected; expected: #{revision} got: #{aggregate.revision}"
      end
    end
  end
end
