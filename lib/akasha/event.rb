require 'securerandom'
require 'time'

module Akasha
  # Event contains all information pertaining to a single
  # event recorded by the system.
  class Event
    attr_reader :id, :name, :data, :created_at

    def initialize(name, id = nil, created_at = Time.now.utc, **data)
      @id = id || SecureRandom.uuid.to_s # TODO: Use something better.
      @name = name
      @created_at = created_at
      @data = data
    end

    def metadata
      {
        created_at: @created_at
      }
    end

    def ==(other) # rubocop:disable Metrics/AbcSize
      self.class == other.class &&
        id == other.id &&
        name == other.name &&
        data == other.data &&
        created_at == other.created_at
    end
  end
end
