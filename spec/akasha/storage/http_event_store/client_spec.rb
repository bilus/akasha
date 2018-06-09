require 'securerandom'

describe Akasha::Storage::HttpEventStore::Client, integration: true do
  subject { http_event_store_client }
  let(:stream) { SecureRandom.uuid.to_s }
  let(:events) do
    [
      Akasha::Event.new(:something_happened, foo: 'bar'),
      Akasha::Event.new(:it_finished, baz: 'qux')
    ]
  end

  describe '#retry_append_to_stream' do
    let(:actual_events) { subject.retry_read_events_forward(stream, 0, 999) }

    it 'saves all events' do
      subject.retry_append_to_stream(stream, events)
      expect(actual_events.map(&:name)).to eq events.map(&:name).reverse
    end

    it 'can save event without data' do
      event = Akasha::Event.new(:problem_occurred)
      subject.retry_append_to_stream(stream, [event])
      expect(actual_events.size).to eq 1
    end

    it 'can preserves event id if set' do
      id = SecureRandom.uuid.to_s
      event = Akasha::Event.new(:problem_occurred, id, foo: 'bar')
      subject.retry_append_to_stream(stream, [event])
      expect(actual_events.first.id).to eq id
    end
  end

  describe '#retry_read_events_forward' do
    before do
      subject.retry_append_to_stream(stream, events)
    end

    it 'retrives events with ids' do
      expect(subject.retry_read_events_forward(stream, 0, 999).map(&:id)).to_not include nil
    end

    it 'retrieves saved data oldest-first' do
      expect(subject.retry_read_events_forward(stream, 0, 999).map(&:data))
        .to match [{ foo: 'bar' }, { baz: 'qux' }].reverse
    end

    it 'returns empty array if stream does not exist' do
      expect(subject.retry_read_events_forward('not-exists', 0, 999)).to eq []
    end

    it 'raises exception if stream name is invalid' do
      expect { subject.retry_read_events_forward('@#$@#$', 0, 999) }
        .to raise_error Akasha::Storage::HttpEventStore::InvalidStreamNameError
    end

    it 'can read events page by page' do
      expect(subject.retry_read_events_forward(stream, 0, 1)).to_not be_empty
      expect(subject.retry_read_events_forward(stream, 1, 1)).to_not be_empty
      expect(subject.retry_read_events_forward(stream, 2, 1)).to be_empty
    end
  end
end
