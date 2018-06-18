RSpec::Matchers.define :match_events do |expected|
  match do |actual|
    actual.map { |e| event_info(e) } == expected.map { |e| event_info(e) }
  end
end

def event_info(event)
  {
    name: event.name,
    data: event.data
  }
end
