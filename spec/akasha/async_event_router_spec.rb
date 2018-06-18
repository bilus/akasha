
# TODO: Simplify initialization!
describe Akasha::AsyncEventRouter, integration: true do
  let(:repository) { Akasha::Repository.new(store) }
  let(:store) { Akasha::Storage::HttpEventStore.new(http_es_config) }
  let(:projection_name) { gensym(:projection) }
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
    @thread = subject.connect!(repository, projection_name: projection_name)
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
      expected_calls = [
        :"on_#{name_changed_event}",
        :"on_#{something_happened_event}",
        :"on_#{name_changed_event}"
      ]
      wait(10).for { listener.calls }.to eq expected_calls
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
