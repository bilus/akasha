
# TODO: Simplify initialization!
describe Akasha::AsyncEventRouter, integration: true do
  subject { described_class.new(projection_stream.name, checkpoint_strategy) }
  let(:repository) { Akasha::Repository.new(store) }
  let(:store) { Akasha::Storage::HttpEventStore.new(http_es_config) }
  let(:checkpoint_strategy) { Akasha::Checkpoint::HttpEventStoreCheckpoint.new(projection_stream) }
  let(:projection_stream) { store.streams[gensym(:projection)] }
  let(:stream_name) { gensym(:stream) }
  let(:name_changed_event) { gensym(:name_changed) }
  let(:something_happened_event) { gensym(:something_happened) }
  let(:ignored_event) { gensym(:ignored_event) }

  let(:events) do
    [
      Akasha::Event.new(name_changed_event, old_name: nil, new_name: 'new name'),
      Akasha::Event.new(something_happened_event),
      Akasha::Event.new(name_changed_event, old_name: 'new_name', new_name: 'newest name'),
      Akasha::Event.new(ignored_event)
    ]
  end

  before do
    Akasha::Aggregate.connect!(repository)
    subject.register_event_listener(name_changed_event, listener)
    subject.register_event_listener(something_happened_event, listener)
    @thread = subject.connect!(repository)
  end

  after do
    @thread.kill
  end

  context 'listener handling name_changed and something_happened' do
    let(:listener) { FakeEventListener.new }

    it 'routes events to listeners' do
      store.streams[stream_name].write_events(events)
      wait(10).for { listener.calls.size }.to eq 3
    end

    it 'preserves ordering' do
      store.streams[stream_name].write_events(events)
      wait(10).for { listener.calls }.to eq [:"on_#{name_changed_event}", :"on_#{something_happened_event}", :"on_#{name_changed_event}"]
    end
  end

  context 'listener failing for something_happened' do
    let(:listener) { FakeEventListener.new(fail_on: [something_happened_event]) }

    it 'handles the remaining two events' do
      store.streams[stream_name].write_events(events)
      wait(10).for { listener.calls.size }.to eq 2
    end
  end
end
