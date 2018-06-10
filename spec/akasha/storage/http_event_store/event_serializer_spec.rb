describe Akasha::Storage::HttpEventStore::EventSerializer do
  let(:events) do
    [
      Akasha::Event.new(:name_changed, old_name: nil, new_name: 'new name'),
      Akasha::Event.new(:name_changed, old_name: 'new_name', new_name: 'newest name')
    ]
  end

  it 'serializes events so they can be deserialized' do
    expect(subject.deserialize(subject.serialize(events))).to match_array events
  end

  it 'serializes events so they can be deserialized from JSON' do
    expect(subject.deserialize(subject.serialize(events))).to eq events
  end
end
