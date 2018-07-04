require_relative 'event_router_base'
require_relative 'checkpoint/metadata_checkpoint'

module Akasha
  # Event router working that can run in the background, providing eventual
  # consistency. Can use the same EventListeners as the synchronous EventRouter.
  class AsyncEventRouter < EventRouterBase
    DEFAULT_POLL_SECONDS = 2
    DEFAULT_PAGE_SIZE = 20
    DEFAULT_PROJECTION_STREAM = 'AsyncEventRouter'.freeze
    DEFAULT_CHECKPOINT_STRATEGY = Akasha::Checkpoint::MetadataCheckpoint
    STREAM_NAME_SEP = '-'.freeze

    def connect!(repository, projection_name: nil,
                 checkpoint_strategy: DEFAULT_CHECKPOINT_STRATEGY,
                 page_size: DEFAULT_PAGE_SIZE, poll: DEFAULT_POLL_SECONDS)
      projection_name = projection_name(repository) if projection_name.nil?
      repository.merge_all_by_event(into: projection_name,
                                    only: registered_event_names)
      projection_stream = repository.store.streams[projection_name]
      checkpoint = checkpoint_strategy.is_a?(Class) ? checkpoint_strategy.new(projection_stream) : checkpoint_strategy
      Thread.new do
        run_forever(projection_stream, checkpoint, page_size, poll)
      end
    end

    private

    # TODO: Make it stoppable.
    def run_forever(projection_stream, checkpoint, page_size, poll)
      position = checkpoint.latest
      loop do
        projection_stream.read_events(position, page_size, poll: poll) do |events|
          begin
            events.each do |event|
              route(event.name, event.metadata[:aggregate_id], **event.data)
              position = checkpoint.ack(position)
            end
          rescue RuntimeError => e
            puts e # TODO: Decide on a strategy.
            position = checkpoint.ack(position)
          end
        end
      end
    rescue RutimeError => e
      puts e # TODO: Decide on a strategy.
      raise
    end

    def projection_name(repository)
      parts = []
      parts << repository.namespace unless repository.namespace.nil?
      parts << DEFAULT_PROJECTION_STREAM
      parts.join(STREAM_NAME_SEP)
    end
  end
end
