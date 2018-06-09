require 'time'

module Akasha
  # Event contains all information pertaining to a single
  # event recorded by the system.
  class Event
    attr_reader :id, :name, :data, :created_at

    def initialize(name, id = nil, created_at = Time.now.utc, **data)
      @id = id
      @name = name
      @created_at = created_at
      @data = data
    end

    def metadata
      {
        created_at: @created_at
      }
    end

    def ==(other)
      self.class == other.class &&
        id == other.id &&
        name == other.name &&
        data == other.data &&
        created_at == other.created_at
    end
  end
end
