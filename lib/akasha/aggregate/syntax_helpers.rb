module Akasha
  # Adds syntax sugar to aggregates.
  #
  # Initialize using the `connect!` method:
  #      repository = Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new)
  #      Aggregate.connect!(repository)
  #
  # Example usage:
  #      item = Item.find_or_create('item-1')
  #      ... modify item ..
  #      item.save!
  #
  module SyntaxHelpers
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    # Aggregate class methods.
    module ClassMethods
      # Connects to a repository.
      def connect!(repository)
        @@repository = repository
      end

      # Returns repository or nil if `connect!` not called.
      def repository
        @@repository
      end

      # Creates and loads the aggregate.
      def find_or_create(id)
        @@repository.load_aggregate(self, id)
      end
    end

    # Aggregate instance methods.
    module InstanceMethods
      # Saves the aggregate.
      def save!
        self.class.repository.save_aggregate(self)
      end
    end
  end
end
