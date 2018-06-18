require 'ostruct'
require 'securerandom'
require 'time'

module Akasha
  # Describes a single event recorded by the system.
  class Event
    attr_reader :id, :name, :data, :metadata

    def initialize(name, id = nil, metadata = OpenStruct.new, **data)
      @id = id || SecureRandom.uuid.to_s # TODO: Use something better.
      @name = name
      @metadata = metadata || OpenStruct.new(created_at: Time.now.utc)
      @data = data
    end

    def ==(other)
      self.class == other.class &&
        id == other.id &&
        name == other.name &&
        data == other.data &&
        metadata == other.metadata
    end
  end
end
