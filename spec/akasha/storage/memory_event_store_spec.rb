describe Akasha::Storage::MemoryEventStore do
  describe '#streams' do
    it 'returns a new stream for different stream names' do
      expect(subject.streams[:foo]).to_not be(subject.streams[:bar])
    end
  end

  describe '#merge_all_by_event' do
    let(:stream_name) { 'some-projection' }
    let(:events) do
      [
        Akasha::Event.new(:world_created),
        Akasha::Event.new(:ruby_invented),
        Akasha::Event.new(:world_ended)
      ]
    end

    before do
      subject.merge_all_by_event(into: stream_name, only: %i[world_created world_ended])
      subject.streams['stream-foo'].write_events(events)
    end

    it 'creates stream containing events with matching names' do
      event_names = subject.streams[stream_name].read_events(0, 999).map(&:name).uniq
      expect(event_names).to match_array(%i[world_created world_ended])
    end
  end
end
