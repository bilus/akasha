describe Akasha::Repository do
  subject { described_class.new(store)}
  let(:store) { Akasha::Storage::MemoryEventStore.new }
  let(:item) { Item.new('item-1') }

  describe '#load_aggregate' do
    let(:events) do
      [
        Akasha::Event.new(:name_changed, old_name: 'foo', new_name: 'bar'),
        Akasha::Event.new(:name_changed, old_name: 'bar', new_name: 'baz')
      ]
    end

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
      before do
        item.name = 'foo'
        subject.save_aggregate(item)
      end

      it 'loads the aggregate' do
        item = subject.load_aggregate(Item, 'item-1')
        expect(item.name).to eq 'foo'
      end
    end
  end

  describe '#save_aggregate' do
    it 'saves new empty aggregate' do
      expect { subject.save_aggregate(item) }.to_not raise_error
    end

    it 'saves a non-empty aggregate' do
      item.name = 'new name' # Generate an event.
      expect { subject.save_aggregate(item) }.to_not raise_error
    end
  end
end
