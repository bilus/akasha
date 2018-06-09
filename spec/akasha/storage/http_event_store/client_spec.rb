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
  end

  describe '#retry_read_events_forward' do
    before do
      subject.retry_append_to_stream(stream, events)
    end

    it 'retrives events with ids' do
      expect(subject.retry_read_events_forward(stream, 0, 999).map(&:id)).to_not include nil
    end

    it 'returns empty array if stream does not exist' do
      expect(subject.retry_read_events_forward('not-exists', 0, 999)).to eq []
    end

    it 'raises exception if stream name is invalid' do
      expect { subject.retry_read_events_forward('@#$@#$', 0, 999) }
        .to raise_error Akasha::Storage::HttpEventStore::InvalidStreamNameError
    end

    it 'retrieves saved data'
  end
end
