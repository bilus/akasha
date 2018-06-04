describe Akasha::EventRouter do
  let(:router) { described_class.new }
  let(:repo) { Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new) }

  before do
    Akasha::Aggregate.connect!(repo)
  end

  describe '#route' do
    subject { router.route(:name_changed, 'item-1', new_name: 'new name') }

    context 'without valid target' do
      it 'raises no error' do
        expect { subject }.to_not raise_error
      end
    end

    context 'with valid default target' do
      before do
        router.register_event_listener(:name_changed, Notifier)
      end

      it 'invokes the event handler' do
        expect_any_instance_of(Notifier).to receive(:on_name_changed).with('item-1', new_name: 'new name')
        expect { subject }.to_not raise_error
      end
    end
  end
end
