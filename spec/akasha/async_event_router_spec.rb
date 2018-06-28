
# TODO: Simplify initialization!
describe Akasha::AsyncEventRouter, integration: true do
end

describe Akasha::AsyncEventRouter, integration: true do
  let(:repo) { Akasha::Repository.new(store, namespace: unique_namespace) }
  let(:unique_namespace) { SecureRandom.uuid }
  let(:store) { Akasha::Storage::HttpEventStore.new(http_es_config) }
  let(:item) { Item.new('item-1') }

  # it_behaves_like 'EventRouter'

  before do
    Akasha::Aggregate.connect!(repo)
    subject.register_event_listener(:name_changed, listener)
    subject.register_event_listener(:count_changed, listener)
    @thread = subject.connect!(repo)
  end

  after do
    @thread.kill
  end

  context 'listener handling name_changed and count_changed' do
    let(:listener) { FakeEventListener.new }

    before do
      item.name = 'new name'
      item.count = 5
      item.name = 'newest name'
      item.save!
    end

    it 'routes events to listeners' do
      wait(10).for { listener.calls.size }.to eq 3
    end

    it 'preserves ordering' do
      expected_calls = %i[
        on_name_changed
        on_count_changed
        on_name_changed
      ]
      wait(10).for { listener.calls }.to eq expected_calls
    end

    context 'for events within another namespace' do
      let(:another_namespace) { SecureRandom.uuid }
      let(:another_repo) { Akasha::Repository.new(store, namespace: another_namespace) }

      it 'ignores those events' do
        Akasha::Aggregate.connect!(another_repo)
        item.name = 'different name'
        item.count = 555
        item.save!

        wait(10).for { listener.calls.size }.to eq 3
      end
    end
  end

  context 'listener failing for count_changed' do
    let(:listener) { FakeEventListener.new(fail_on: [:count_changed]) }

    before do
      item.name = 'new name'
      item.count = 5
      item.name = 'newest name'
      item.save!
    end

    it 'handles the remaining two events' do
      wait(10).for { listener.calls.size }.to eq 2
    end
  end
end
