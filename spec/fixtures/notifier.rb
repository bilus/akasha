# An example event listener.
class Notifier < Akasha::EventListener
  # Handle the 'name_changed' event.
  # Specs will spy on this method.
  def on_name_changed(_aggregate_id, new_name:, **); end
end
