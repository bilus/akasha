module Akasha
  module Checkpoint
    # Stores stream position in stream metadata.
    class MetadataCheckpoint
      # Creates a new checkpoint, storing position in `stream` every `interval` events.
      # Use `interval` greater than zero for idempotent event listeners.
      def initialize(stream, interval: 1)
        @stream = stream
        @interval = interval
        return if @stream.respond_to?(:metadata) && @stream.respond_to?(:metadata=)
        raise UnsupportedStorageError, "Storage does not support checkpoints: #{stream.class}"
      end

      # rubocop:disable Naming/MemoizedInstanceVariableName
      # Returns the most recently stored next position.
      def latest
        @next_position ||= (read_position || 0)
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName

      # Returns the next position, conditionally storing it (based on the configurable interval).
      def ack(position)
        @next_position = position + 1
        if (@next_position % @interval).zero?
          # TODO: Race condition; use optimistic cocurrency.
          @stream.metadata = @stream.metadata.merge(next_position: @next_position)
        end
        @next_position
      rescue Akasha::HttpClientError => e
        raise if e.status_code != 404
        raise CheckpointStreamNotFoundError, "Stream cannot be checkpointed; it does not exist: #{@stream.name}"
      end

      protected

      def read_position
        @stream.metadata[:next_position]
      rescue Akasha::HttpClientError => e
        return 0 if e.status_code == 404
        raise
      end
    end
  end
end
