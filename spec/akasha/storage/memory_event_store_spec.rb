describe Akasha::Storage::MemoryEventStore do
  describe '#streams' do
    it 'returns a new stream for different stream names' do
      expect(subject.streams[:foo]).to_not be(subject.streams[:bar])
    end
  end
end
