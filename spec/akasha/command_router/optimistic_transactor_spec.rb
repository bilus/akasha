describe Akasha::CommandRouter::OptimisticTransactor do
  let(:transactor) { described_class.new }

  before do
    Akasha::Aggregate.connect!(repo)
  end

  shared_examples 'saves aggregate' do
    it 'saves events without errors' do
      expect { subject }.to_not raise_error
      item = Item.find_or_create('item-1')
      expect(item.name).to eq 'new name'
    end
  end

  shared_examples 'enabled optimistic concurrency' do
    context 'with no revision' do
      let(:revision) { nil }

      include_examples 'saves aggregate'
    end

    context 'given incorrect revision' do
      let(:revision) { 100 }

      it 'with conflict' do
        expect { subject }.to raise_error described_class::ConflictError
      end
    end

    context 'with correct revision' do
      let(:revision) { -1 }

      context 'without concurrent changes' do
        include_examples 'saves aggregate'
      end

      context 'with a concurrent change' do
        before do
          expect_any_instance_of(Item).to receive(:change_item_name).and_wrap_original do |original, *args|
            item = original.call(*args)

            same_item = Item.find_or_create('item-1')
            same_item.count = 10
            same_item.save!

            item
          end
        end

        it 'detects race condition' do
          expect { subject }.to raise_error Akasha::RaceConditionError
        end
      end
    end
  end

  shared_examples 'optional concurrency support' do
    subject do
      transactor.call(Item,
                      :change_item_name,
                      'item-1',
                      {
                        concurrency: concurrency, revision: revision
                      },
                      new_name: 'new name')
    end

    context 'given default concurrency' do
      let(:concurrency) { nil }

      include_examples 'enabled optimistic concurrency'
    end

    context 'given optimistic concurrency' do
      let(:concurrency) { :optimistic }

      include_examples 'enabled optimistic concurrency'
    end

    context 'given concurrency off' do
      let(:concurrency) { :none }

      context 'with any revision' do
        let(:revision) { 123 }

        it 'raises error' do
          expect { subject }.to raise_error ArgumentError
        end
      end
    end
  end

  describe '#call' do
    let(:repo) { Akasha::Repository.new(store, namespace: gensym(:namespace)) }

    context 'memory-based event store' do
      let(:store) { Akasha::Storage::MemoryEventStore.new }

      include_examples 'optional concurrency support'
    end

    context 'HTTP-backed event store', integration: true do
      let(:store) { Akasha::Storage::HttpEventStore.new(http_es_config) }

      include_examples 'optional concurrency support'
    end
  end
end
