shared_examples 'event router' do
  let(:router) { described_class.new }
  let(:repo) { Akasha::Repository.new(Akasha::Storage::MemoryEventStore.new) }

  before do
    Akasha::Aggregate.connect!(repo)
  end

  shared_examples 'routes registered events' do
    before do
      allow(router).to receive(:log).and_return(nil) # Do not print to stdout.
    end

    it 'invokes all event handlers' do
      expect_any_instance_of(Notifier).to receive(:on_name_changed).with('item-1', new_name: 'new name')
      expect_any_instance_of(ItemLogger).to receive(:on_name_changed).with('item-1', new_name: 'new name')
      expect { subject }.to_not raise_error
    end

    it 'ignores exceptions' do
      expect_any_instance_of(Notifier).to receive(:on_name_changed)
        .with('item-1', new_name: 'new name')
        .and_raise('Oops!')
      expect_any_instance_of(ItemLogger).to receive(:on_name_changed)
        .with('item-1', new_name: 'new name')
        .and_raise('Oops!')
      expect { subject }.to_not raise_error
    end
  end

  describe '#route' do
    subject { router.route(:name_changed, 'item-1', new_name: 'new name') }

    context 'without a valid listener' do
      it 'raises no error' do
        expect { subject }.to_not raise_error
      end
    end

    context 'with a valid listener class' do
      before do
        router.register_event_listener(:name_changed, Notifier)
      end

      it 'invokes the event handler' do
        expect_any_instance_of(Notifier).to receive(:on_name_changed).with('item-1', new_name: 'new name')
        expect { subject }.to_not raise_error
      end
    end

    context 'with a valid listener instance' do
      let(:notifier) { Notifier.new }

      before do
        router.register_event_listener(:name_changed, notifier)
      end

      it 'invokes the event handler' do
        expect(notifier).to receive(:on_name_changed).with('item-1', new_name: 'new name')
        expect { subject }.to_not raise_error
      end
    end

    context 'with multiple valid listeners' do
      before do
        router.register_event_listener(:name_changed, Notifier)
        router.register_event_listener(:name_changed, ItemLogger)
      end

      include_examples 'routes registered events'
    end

    context 'with multiple valid listeners passed to constructor' do
      let(:router) do
        described_class.new(name_changed: [Notifier, ItemLogger])
      end

      include_examples 'routes registered events'
    end
  end
end
