require 'time'

module Akasha
  # Event contains all information pertaining to a single
  # event recorded by the system.
  class Event
    attr_reader :name, :data, :created_at

    def initialize(name, created_at = Time.now.utc, **data)
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
        name == other.name &&
        data == other.data &&
        created_at == other.created_at
    end
  end
end
