describe 'handling commands' do
  let(:repo) { Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new) }

  before do
    Akasha::Aggregate.connect!(repo)
  end

  it 'aggregates are persisted' do
    item = Item.find_or_create('item-1')
    expect(item).to_not be_nil
    item.name = 'new name'
    expect { item.save! }.to_not raise_error

    item = Item.find_or_create('item-1')
    expect(item).to_not be_nil
    expect(item.name).to eq('new name')
  end
end
