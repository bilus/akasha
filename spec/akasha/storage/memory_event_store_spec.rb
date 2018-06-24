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

    context 'given no namespace' do
      before do
        subject.merge_all_by_event(into: stream_name, only: %i[world_created world_ended])
        subject.streams['stream-foo'].write_events(events)
      end

      it 'creates stream containing events with matching names' do
        event_names = subject.streams[stream_name].read_events(0, 999).map(&:name)
        expect(event_names).to match_array(%i[world_created world_ended])
      end

      it 'accepts events regardless of their namespaces' do
        subject.streams['stream-foo'].write_events(events.map { |e| e.with_metadata(namespace: 'another.namespace') })
        event_names = subject.streams[stream_name].read_events(0, 999).map(&:name)
        expect(event_names).to match_array(%i[world_created world_ended world_created world_ended])
      end
    end

    context 'if namespace given' do
      before do
        subject.merge_all_by_event(into: stream_name, only: %i[world_created world_ended],
                                   namespace: 'some.namespace')
        subject.streams['stream-foo'].write_events(events.map { |e| e.with_metadata(namespace: 'some.namespace') })
        subject.streams['stream-foo'].write_events(events) # These should be ignored.
      end

      it 'creates stream containing events with matching names and metadata.namespace' do
        event_names = subject.streams[stream_name].read_events(0, 999).map(&:name)
        expect(event_names).to match_array(%i[world_created world_ended])
      end
    end
  end
end
