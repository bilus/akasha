describe Akasha::CommandRouter do
  let(:router) { described_class.new }
  let(:repo) { Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new) }

  before do
    Akasha::Aggregate.connect!(repo)
  end

  describe '#route!' do
    subject { router.route!(:change_item_name, 'item-1', new_name: 'new name') }

    context 'without valid target' do
      it 'raises error' do
        expect { subject }.to raise_error Akasha::CommandRouter::NotFoundError
      end
    end

    context 'with valid default target' do
      before do
        router.register_default_route(:change_item_name, Item)
      end

      it 'raises no error' do
        expect { subject }.to_not raise_error
      end

      it 'persists changes to the aggregate' do
        router.route!(:change_item_name, 'item-1', new_name: 'new name')
        item = Item.find_or_create('item-1')
        expect(item.name).to eq 'new name'
      end
    end

    context 'with valid custom target' do
      before do
        router.register_route(:change_item_name) do |_command, aggregate_id, **data|
          item = Item.find_or_create(aggregate_id)
          item.name = data[:new_name]
          item.save!
        end
      end

      it 'raises no error' do
        expect { subject }.to_not raise_error
      end

      it 'persists changes to the aggregate' do
        router.route!(:change_item_name, 'item-1', new_name: 'new name')
        item = Item.find_or_create('item-1')
        expect(item.name).to eq 'new name'
      end
    end
  end
end
