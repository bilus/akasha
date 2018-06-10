require 'securerandom'
require 'time'

module Akasha
  # Event contains all information pertaining to a single
  # event recorded by the system.
  class Event
    attr_reader :id, :name, :data, :created_at
    attr_accessor :saved_at

    def initialize(name, id = nil, created_at = Time.now.utc, saved_at = nil, **data)
      @id = id || SecureRandom.uuid.to_s # TODO: Use something better.
      @name = name
      @created_at = created_at
      @saved_at = saved_at
      @data = data
    end

    def ==(other) # rubocop:disable Metrics/AbcSize
      self.class == other.class &&
        id == other.id &&
        name == other.name &&
        data == other.data &&
        created_at&.iso8601 == other.created_at&.iso8601 &&
        saved_at&.iso8601 == other.saved_at&.iso8601
    end
  end
end
