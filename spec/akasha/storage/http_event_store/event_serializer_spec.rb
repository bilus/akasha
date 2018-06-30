describe Akasha::Storage::HttpEventStore::EventSerializer do
  let(:id1) { 'id1' }
  let(:id2) { 'id2' }
  let(:id3) { 'id3' }
  let(:events) do
    [
      Akasha::Event.new(:name_changed, id1, old_name: nil, new_name: 'new name'),
      Akasha::Event.new(:name_changed, id2, old_name: 'new_name', new_name: 'newest name'),
      Akasha::Event.new(:name_changed, id3, { foo: 'bar' }, baz: 'qux')
    ]
  end

  let(:recorded_events) do
    [
      Akasha::RecordedEvent.new(:name_changed, id1, 0, updated_at, {}, old_name: nil, new_name: 'new name'),
      Akasha::RecordedEvent.new(:name_changed, id2, 1, updated_at, {}, old_name: 'new_name', new_name: 'newest name'),
      Akasha::RecordedEvent.new(:name_changed, id3, 2, updated_at, { foo: 'bar' }, baz: 'qux')
    ]
  end

  let(:updated_at) { Time.now.utc }

  it 'serializes events so they can be deserialized from JSON' do
    serialized = subject.serialize(events)
    serialized = serialized.each_with_index.map do |ev, i|
      ev.merge('updated' => updated_at.iso8601, 'eventNumber' => i) # Normally coming from Eventstore.
    end
    expect(subject.deserialize(serialized)).to eq recorded_events
  end
end
