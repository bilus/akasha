describe Akasha::CommandRouter do
  let(:router) { described_class.new(routes) }
  let(:repo) { Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new) }

  before do
    Akasha::Aggregate.connect!(repo)
  end

  shared_examples 'routes registered command' do
    it 'raises no error' do
      expect { subject }.to_not raise_error
    end

    it 'persists changes to the aggregate' do
      router.route!(:change_item_name, 'item-1', {}, new_name: 'new name')
      item = Item.find_or_create('item-1')
      expect(item.name).to eq 'new name'
    end
  end

  describe '#route!' do
    subject { router.route!(:change_item_name, 'item-1', new_name: 'new name') }

    context 'without valid target' do
      let(:routes) { {} }

      it 'raises error' do
        expect { subject }.to raise_error Akasha::CommandRouter::NotFoundError
      end
    end

    context 'with valid default target' do
      let(:routes) do
        {
          change_item_name: Item
        }
      end

      include_examples 'routes registered command'
    end

    context 'with valid custom handler' do
      let(:routes) do
        {
          change_item_name: handler
        }
      end

      let(:handler) do
        lambda do |_command, aggregate_id, _options, **data|
          item = Item.find_or_create(aggregate_id)
          item.name = data[:new_name]
          item.save!
        end
      end

      include_examples 'routes registered command'
    end

    context 'with valid default target registered via constructor' do
      let(:router) { described_class.new(change_item_name: Item) }

      include_examples 'routes registered command'
    end

    context 'with valid custom target registered via constructor' do
      let(:router) do
        described_class.new(change_item_name: lambda do |_command, aggregate_id, _options, **data|
          item = Item.find_or_create(aggregate_id)
          item.name = data[:new_name]
          item.save!
        end)
      end

      include_examples 'routes registered command'
    end
  end
end
