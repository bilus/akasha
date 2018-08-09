describe Akasha::Repository do
  subject { described_class.new(store, namespace: gensym(:namespace)) }
  let(:item) { Item.new('item-1') }

  shared_examples 'loading aggregates' do
    context 'for a non-existent aggregate' do
      it 'succeeds' do
        expect { subject.load_aggregate(Item, 'item-1') }.to_not raise_error
      end

      it 'returns a new aggregate' do
        item = subject.load_aggregate(Item, 'item-1')
        expect(item.name).to be_nil
      end
    end

    context 'for an existing aggregate' do
      context 'within the same namespace' do
        it 'loads the aggregate' do
          item.name = 'foo'
          subject.save_aggregate(item)
          item = subject.load_aggregate(Item, 'item-1')
          expect(item.name).to eq 'foo'
        end

        it 'applies events in the right order' do
          item.name = 'foo'
          item.name = 'bar'
          subject.save_aggregate(item)
          item = subject.load_aggregate(Item, 'item-1')
          expect(item.name).to eq 'bar'
        end

        it 'correctly handles pagination' do
          100.times do
            item.name = 'foo'
          end
          item.name = 'bar'
          subject.save_aggregate(item)
          item = subject.load_aggregate(Item, 'item-1')
          expect(item.name).to eq 'bar'
        end
      end

      context 'within a different namespace' do
        let(:another_repo) { described_class.new(store, namespace: 'another.namespace') }

        before do
          item.name = 'foo'
          another_repo.save_aggregate(item)
        end

        it 'returns a new aggregate' do
          item = subject.load_aggregate(Item, 'item-1')
          expect(item.name).to be_nil
        end
      end
    end
  end

  shared_examples 'optimistic concurrency' do
    let!(:item) { subject.load_aggregate(Item, 'item-1') }

    context 'given no changes between load and save' do
      it 'saves the aggregate' do
        item.name = 'new name' # Generate an event.
        expect { subject.save_aggregate(item, concurrency: :optimistic) }.to_not raise_error
      end
    end

    context 'given changes between load and save' do
      it 'detects race condition' do
        # Aggregate was loaded by this point due to `let!`.

        # Make concurrent change.
        same_item = subject.load_aggregate(Item, 'item-1')
        same_item.name = 'another name'
        subject.save_aggregate(same_item)

        # Save our changes.
        item.name = 'new name' # Generate an event.
        expect { subject.save_aggregate(item, concurrency: :optimistic) }
          .to raise_error Akasha::ConflictError
      end
    end
  end

  shared_examples 'saving aggregates' do
    context 'with optimistic concurrency disabled' do
      it 'saves new empty aggregate' do
        expect { subject.save_aggregate(item) }.to_not raise_error
      end

      it 'saves a non-empty aggregate' do
        item.name = 'new name' # Generate an event.
        expect { subject.save_aggregate(item) }.to_not raise_error
      end
    end

    context 'with optimistic concurrency enabled' do
      context 'given new, empty aggregate' do
        include_examples 'optimistic concurrency'
      end

      context 'given an existing aggregate' do
        before do
          same_item = subject.load_aggregate(Item, 'item-1')
          same_item.name = 'another name'
          subject.save_aggregate(same_item)
        end

        include_examples 'optimistic concurrency'
      end
    end
  end

  describe '#subscribe' do
    let(:store) { Akasha::Storage::MemoryEventStore.new }
    let(:sub) { double(:sub) }

    before do
      Timecop.freeze
      subject.subscribe(sub)
    end

    after do
      Timecop.return
    end

    it 'calls subscriber for every event written to storage' do
      expect(sub).to receive(:call).twice
      item = subject.load_aggregate(Item, 'item-1')
      item.name = 'foo'
      subject.save_aggregate(item)
      item = subject.load_aggregate(Item, 'item-1')
      item.name = 'bar'
      subject.save_aggregate(item)
    end
  end

  describe '#load_aggregate' do
    context 'with memory-based event store' do
      let(:store) { Akasha::Storage::MemoryEventStore.new }

      include_examples 'loading aggregates'
    end

    context 'with HTTP-backed event store', integration: true do
      let(:store) { Akasha::Storage::HttpEventStore.new(http_es_config) }

      include_examples 'loading aggregates'
    end
  end

  describe '#save_aggregate' do
    context 'with memory-based event store' do
      let(:store) { Akasha::Storage::MemoryEventStore.new }

      include_examples 'saving aggregates'
    end

    context 'with HTTP-backed event store', integration: true do
      let(:store) { Akasha::Storage::HttpEventStore.new(http_es_config) }

      include_examples 'saving aggregates'
    end
  end
end
