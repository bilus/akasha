require_relative 'changeset'
require_relative 'aggregate/syntax_helpers'

module Akasha
  # CQRS Aggregate base class.
  #
  # Usage:
  #
  # class User < Akasha::Aggregate
  #   def sign_up(email, password)
  #     changeset.append(:user_signed_up, email: email, password: password)
  #   end
  #
  #   def on_user_signed_up(email:, password:, **_)
  #     @email = email
  #     @password = password
  #   end
  # end
  class Aggregate
    include SyntaxHelpers

    attr_reader :id, :changeset, :revision

    def initialize(id)
      @revision = -1 # No stream exists.
      @id = id
      @changeset = Changeset.new(self)
    end

    # Replay events, building up the state of the aggregate.
    # Used by Repository.
    def apply_events(events)
      events.each do |event|
        method_name = event_handler(event)
        public_send(method_name, event.data) if respond_to?(method_name)
      end
      @revision = events.last&.revision.to_i if events.last.respond_to?(:revision)
    end

    private

    def event_handler(event)
      :"on_#{event.name}"
    end
  end
end
