# An example event listener.
class ItemLogger < Akasha::EventListener
  # Handle the 'name_changed' event.
  # Specs will spy on this method.
  def on_name_changed(_aggregate_id, **); end
end
