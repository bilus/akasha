describe Akasha::Storage::HttpEventStore, integration: true do
  subject { described_class.new(http_es_config) }

  describe '#streams' do
    it 'returns a new stream for different stream names' do
      expect(subject.streams[:foo]).to_not be(subject.streams[:bar])
    end
  end

  describe '#merge_all_by_event' do
    let(:projection_name) { gensym(:projection) }
    let(:stream_name) { gensym(:stream) }
    let(:parallel_universe) { gensym('parallel.universe') }
    let(:our_universe) { gensym('our.universe') }
    let(:events) do
      [
        Akasha::Event.new(:world_created).with_metadata(namespace: our_universe),
        Akasha::Event.new(:ruby_invented).with_metadata(namespace: our_universe),
        Akasha::Event.new(:world_ended).with_metadata(namespace: our_universe),
        Akasha::Event.new(:world_created).with_metadata(namespace: parallel_universe),
        Akasha::Event.new(:world_ended).with_metadata(namespace: parallel_universe)
      ]
    end
    let(:poll_seconds) { 1 }

    context 'given a projection without a namespace' do
      before do
        subject.merge_all_by_event(into: projection_name, only: %i[world_created world_ended])
        subject.streams[stream_name].write_events(events)
      end

      it 'creates stream containing events with matching names' do
        wait(10).for do
          subject.streams[projection_name].read_events(0, 999, poll_seconds).map(&:name).uniq
        end.to match_array(%i[world_created world_ended])
      end

      it 'accepts events regardless of their namespace' do
        wait(10).for do
          subject.streams[projection_name].read_events(0, 999, poll_seconds).size
        end.to be >= 4 # Because other tests will create events as well.
      end
    end

    context 'given a projection within a namespace' do
      before do
        subject.merge_all_by_event(into: projection_name, only: %i[world_created world_ended],
                                   namespace: our_universe)
        subject.streams[stream_name].write_events(events)
      end

      it 'optionally accepts event only from the specified namespace' do
        wait(10).for do
          subject.streams[projection_name].read_events(0, 999, poll_seconds).map(&:name)
        end.to match_array(%i[world_created world_ended])
      end
    end

    it 'supports changing the list of names' do
      subject.merge_all_by_event(into: projection_name, only: %i[world_created world_ended], namespace: our_universe)
      subject.streams[projection_name].read_events(0, 999, poll_seconds)
      subject.merge_all_by_event(into: projection_name, only: [:world_created], namespace: our_universe)
      subject.streams[stream_name].write_events(events)

      wait(10).for do
        subject.streams[projection_name].read_events(0, 999, poll_seconds).map(&:name).uniq
      end.to match_array([:world_created])
    end
  end
end
