class Item < Akasha::Aggregate
  attr_reader :name

  def initialize(id)
    super(id)
  end

  def name=(new_name)
    changeset << Akasha::Event.new(:name_changed, old_name: @name, new_name: new_name)
  end

  def on_name_changed(new_name:, **_kwargs)
    @name = new_name
  end
end
