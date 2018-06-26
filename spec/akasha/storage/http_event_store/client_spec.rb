require 'securerandom'

describe Akasha::Storage::HttpEventStore::Client, integration: true do
  subject { http_event_store_client }
  let(:stream) { gensym(:stream) }
  let(:events) do
    [
      Akasha::Event.new(:something_happened, foo: 'bar'),
      Akasha::Event.new(:it_finished, baz: 'qux')
    ]
  end

  describe '#retry_append_to_stream' do
    let(:actual_events) { subject.retry_read_events_forward(stream, 0, 999, max_retries: max_retries) }
    let(:max_retries) { 0 }

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

    it 'optionally retries on network errors' do
      expect(subject).to(receive(:append_to_stream)).ordered.twice.and_raise(Faraday::TimeoutError)
      expect(subject).to(receive(:append_to_stream)).ordered.once.and_call_original
      subject.retry_append_to_stream(stream, events, max_retries: 2)
      expect(actual_events).to_not be_empty
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

    it 'retries optionally on network errors' do
      expect(subject).to(receive(:safe_read_events)).ordered.twice.and_raise(Faraday::TimeoutError)
      expect(subject).to(receive(:safe_read_events)).ordered.once.and_call_original
      expect(subject.retry_read_events_forward(stream, 0, 1, max_retries: 2)).to_not be_empty
    end
  end

  shared_context 'existing stream' do
    let(:existing_stream) { gensym(:stream) }

    before do
      subject.retry_append_to_stream(existing_stream, events)
    end
  end

  describe '#retry_read_metadata' do
    include_context 'existing stream'

    let(:metadata) do
      {
        :$maxCount => 1,
        foo: 'bar'
      }
    end

    it 'is a hash' do
      expect(subject.retry_read_metadata(existing_stream)).to be_a Hash
    end

    it 'retries optionally on network errors' do
      subject.retry_write_metadata(existing_stream, metadata)
      expect(subject).to(receive(:safe_read_metadata)).ordered.twice.and_raise(Faraday::TimeoutError)
      expect(subject).to(receive(:safe_read_metadata)).ordered.once.and_call_original
      expect(subject.retry_read_metadata(existing_stream, max_retries: 2)).to include(metadata)
    end
  end

  describe '#retry_write_metadata' do
    include_context 'existing stream'

    let(:metadata) do
      {
        :$maxCount => 1,
        foo: 'bar'
      }
    end

    it 'sets stream metadata' do
      subject.retry_write_metadata(existing_stream, metadata)
      expect(subject.retry_read_metadata(existing_stream)).to include(metadata)
    end

    it 'optionally retries on network errors' do
      expect(subject).to(receive(:append_to_stream)).ordered.twice.and_raise(Faraday::TimeoutError)
      expect(subject).to(receive(:append_to_stream)).ordered.once.and_call_original
      subject.retry_write_metadata(existing_stream, metadata, max_retries: 2)
      expect(subject.retry_read_metadata(existing_stream)).to include(metadata)
    end
  end
end
