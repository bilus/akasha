describe Akasha::Checkpoint::HttpEventStoreCheckpoint, integration: true do
  let(:checkpoint) { described_class.new(repository.streams[stream]) }
  let(:stream) { gensym(:stream) }
  let(:repository) { Akasha::Storage::HttpEventStore.new(http_es_config) }

  let(:events) do
    [
      Akasha::Event.new(:name_changed, old_name: nil, new_name: 'new name'),
      Akasha::Event.new(:name_changed, old_name: 'new_name', new_name: 'newest name')
    ]
  end

  describe '#latest' do
    subject { checkpoint.latest }

    context 'for an empty stream' do
      context 'for empty checkpoint' do
        it { is_expected.to be_zero }
      end
    end

    context 'for a non-empty stream' do
      before do
        repository.streams[stream].write_events(events)
      end

      context 'for empty checkpoint' do
        it { is_expected.to be_zero }
      end

      context 'for checkpoint that was updated' do
        before do
          checkpoint.ack(0)
          checkpoint.ack(1)
          checkpoint.ack(4)
        end

        it { is_expected.to eq 5 }

        it 'persists state' do
          loaded = described_class.new(repository.streams[stream])
          expect(loaded.latest).to eq 5
        end
      end
    end
  end

  shared_examples 'saving checkpoints' do
    subject { checkpoint.latest }
    let(:other_instance) { described_class.new(repository[stream], interval: interval) }
    let(:interval) { 1 }

    context 'with checkpoints after each event' do
      let(:interval) { 1 }

      (0..2).each do |position|
        it "saves position #{position}" do
          other_instance.ack(position)
          expect(subject).to eq(position + 1)
        end
      end
    end

    context 'with checkpoint after every 3rd event' do
      let(:interval) { 3 }

      it 'does not save position 0' do
        other_instance.ack(0)
        expect(other_instance.latest).to eq 1
        expect(subject).to eq(0)
      end

      it 'does not save position 1' do
        other_instance.ack(1)
        expect(other_instance.latest).to eq 2
        expect(subject).to eq(0)
      end

      it 'saves position 2' do
        other_instance.ack(2)
        expect(other_instance.latest).to eq 3
        expect(subject).to eq(3)
      end
    end
  end

  describe '#ack' do
    context 'for an empty stream' do
      include_examples 'saving checkpoints'
    end

    context 'for a non-empty stream' do
      before do
        repository.streams[stream].write_events(events)
      end

      include_examples 'saving checkpoints'
    end
  end
end
