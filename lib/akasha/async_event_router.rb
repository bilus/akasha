require_relative 'event_router_base'

module Akasha
  # Event router working that can run in the background, providing eventual
  # consistency. Can use the same EventListeners as the synchronous EventRouter.
  class AsyncEventRouter < EventRouterBase
    DEFAULT_POLL_SECONDS = 10
    DEFAULT_PAGE_SIZE = 20

    def initialize(projection_name, checkpoint_strategy)
      super()
      @checkpoint = checkpoint_strategy
      @projection_name = projection_name
    end

    # TODO: Change it so connect! returns the thread.

    def connect!(repository, page_size: DEFAULT_PAGE_SIZE, poll: DEFAULT_POLL_SECONDS)
      repository.merge_all_by_event(into: @projection_name, only: registered_event_names)
      projection_stream = repository.store.streams[@projection_name]
      Thread.new do
        run_forever(projection_stream, page_size, poll)
      end
    end

    private

    # TODO: Make it stoppable.
    def run_forever(projection_stream, page_size, poll)
      position = @checkpoint.latest
      loop do
        projection_stream.read_events(position, page_size, poll) do |events|
          begin
            events.each do |event|
              route(event.name, event.metadata.aggregate_id, **event.data)
              position = @checkpoint.ack(position)
            end
          rescue => e
            puts e # TODO: Decide on a strategy.
            position = @checkpoint.ack(position)
          end
        end
      end
    end
  end
end
