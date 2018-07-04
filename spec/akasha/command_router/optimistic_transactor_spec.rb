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
        expect { subject }.to raise_error Akasha::StaleRevisionError
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
          expect { subject }.to raise_error Akasha::ConflictError
        end
      end
    end
  end

  shared_examples 'optional concurrency support' do
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

  shared_examples 'retries in case of conflicts' do
    context 'with optimistic concurrency and 2 retries' do
      let(:concurrency) { :optimistic }
      let(:revision) { nil }
      let(:retries) { 2 }
      let(:item) { double(:item, change_item_name: nil) }

      before do
        # Mocking `new` because of the limitations of `expect_any_instance_of.`
        allow(Item).to receive(:new).and_return(item)
      end

      it 'retries until conflict resolved' do
        expect(item).to receive(:save!).exactly(3).times.and_raise Akasha::ConflictError
        expect { subject }.to raise_error Akasha::ConflictError
      end

      it 'retries until max retries reached' do
        expect(item).to receive(:save!).ordered.twice.and_raise Akasha::ConflictError
        expect(item).to receive(:save!).ordered.once
        expect { subject }.to_not raise_error
      end
    end
  end

  describe '#call' do
    subject do
      transactor.call(Item,
                      :change_item_name,
                      'item-1',
                      {
                        concurrency: concurrency,
                        revision: revision,
                        max_conflict_retries: retries
                      },
                      new_name: 'new name')
    end
    let(:retries) { 0 }
    let(:repo) { Akasha::Repository.new(store, namespace: gensym(:namespace)) }

    context 'memory-based event store' do
      let(:store) { Akasha::Storage::MemoryEventStore.new }

      include_examples 'optional concurrency support'
      include_examples 'retries in case of conflicts'
    end

    context 'HTTP-backed event store', integration: true do
      let(:store) { Akasha::Storage::HttpEventStore.new(http_es_config) }

      include_examples 'optional concurrency support'
      include_examples 'retries in case of conflicts'
    end
  end
end
