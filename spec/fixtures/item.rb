# An example aggregate.
class Item < Akasha::Aggregate
  attr_reader :name, :count

  # Attribute accessors can use events too!
  def name=(new_name)
    changeset.append(:name_changed, old_name: @name, new_name: new_name)
  end

  def count=(new_count)
    changeset.append(:count_changed, old_count: @count, new_count: new_count)
  end

  # Alias for default command routing.
  def change_item_name(new_name:, **)
    self.name = new_name # This will generate the event!
  end

  # This is how you apply events to build aggregate state.
  def on_name_changed(new_name:, **)
    @name = new_name
  end

  def on_count_changed(new_count:, **)
    @count = new_count
  end
end
