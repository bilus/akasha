require_relative 'event_router_base'
require_relative 'checkpoint/http_event_store_checkpoint'

module Akasha
  # Event router working that can run in the background, providing eventual
  # consistency. Can use the same EventListeners as the synchronous EventRouter.
  class AsyncEventRouter < EventRouterBase
    DEFAULT_POLL_SECONDS = 10
    DEFAULT_PAGE_SIZE = 20
    DEFAULT_PROJECTION_STREAM = 'AsyncEventRouter'.freeze
    DEFAULT_CHECKPOINT_STRATEGY = Akasha::Checkpoint::HttpEventStoreCheckpoint

    def connect!(repository, projection_name: DEFAULT_PROJECTION_STREAM,
                             checkpoint_strategy: DEFAULT_CHECKPOINT_STRATEGY,
                             page_size: DEFAULT_PAGE_SIZE, poll: DEFAULT_POLL_SECONDS)
      projection_stream = repository.store.streams[projection_name]
      checkpoint = checkpoint_strategy.is_a?(Class) ? checkpoint_strategy.new(projection_stream) : checkpoint_strategy
      repository.merge_all_by_event(into: projection_name, only: registered_event_names)
      Thread.new do
        run_forever(projection_stream, checkpoint, page_size, poll)
      end
    end

    private

    # TODO: Make it stoppable.
    def run_forever(projection_stream, checkpoint, page_size, poll)
      position = checkpoint.latest
      loop do
        projection_stream.read_events(position, page_size, poll) do |events|
          begin
            events.each do |event|
              route(event.name, event.metadata.aggregate_id, **event.data)
              position = checkpoint.ack(position)
            end
          rescue RuntimeError => e
            puts e # TODO: Decide on a strategy.
            position = checkpoint.ack(position)
          end
        end
      end
    end
  end
end
