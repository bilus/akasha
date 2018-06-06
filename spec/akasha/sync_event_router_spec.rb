describe Akasha::SyncEventRouter do
  subject { described_class.new }
  let(:repo) { Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new) }
  let(:item) { Item.new('item-1') }

  before do
    Akasha::Aggregate.connect!(repo)
  end

  describe '#connect' do
    before do
      subject.register_event_listener(:name_changed, Notifier)
    end

    it "routes repo's events" do
      subject.connect!(repo)
      item.name = 'new name'
      expect_any_instance_of(Notifier).to receive(:on_name_changed).with('item-1', old_name: nil, new_name: 'new name')
      repo.save_aggregate(item)
    end
  end
end
