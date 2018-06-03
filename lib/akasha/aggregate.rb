require_relative 'changeset'
require_relative 'aggregate/syntax_helpers'

module Akasha
  # CQRS Aggregate base class.
  #
  # Usage:
  #
  # class User < Akasha::Aggregate
  #   def sign_up(email, password)
  #     changeset << Akasha::Event.new(:user_signed_up, email: email, password: password)
  #   end
  #
  #   def on_user_signed_up(email:, password:, **_)
  #     @email = email
  #     @password = password
  #   end
  # end
  class Aggregate
    include SyntaxHelpers

    attr_reader :changeset

    def initialize(id)
      @changeset = Changeset.new(id)
    end

    # Replay events, building up the state of the aggregate.
    # Used by Repository.
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
