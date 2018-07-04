require_relative './event'

module Akasha
  # Event read from a stream.
  class RecordedEvent < Event
    attr_reader :revision, :updated_at

    def initialize(name, id, revision, updated_at, metadata, **data)
      super(name, id, metadata, **data)
      @revision = revision
      @updated_at = updated_at
    end

    def ==(other)
      super(other) &&
        @revision == other.revision &&
        @updated_at.utc.iso8601 == other.updated_at.utc.iso8601
    end
  end
end
