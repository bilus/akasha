describe Akasha::SyntaxHelpers do
  subject { Item.new('item-1') }
  let(:repo) { Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new) }

  before do
    Akasha::Aggregate.connect!(repo)
  end

  describe '#find_or_create' do
    it 'creates new aggregate' do
      item = Item.find_or_create('item-1')
      expect(item).to_not be_nil
      expect(item).to be_an Item
    end

    it 'finds existing aggregate' do
      item = Item.find_or_create('item-1')
      item.name = 'new name'
      item.save!

      item = Item.find_or_create('item-1')
      expect(item).to_not be_nil
      expect(item).to be_an Item
      expect(item.name).to eq('new name')
    end
  end

  describe '#save!' do
    it 'persists changes to a modified aggregate' do
      subject.name = 'new name'
      expect { subject.save! }.to_not raise_error

      item = Item.find_or_create('item-1')
      expect(item.name).to eq('new name')
    end
  end
end
