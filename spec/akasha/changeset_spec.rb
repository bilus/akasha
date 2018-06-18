describe Akasha::Changeset do
  subject { described_class.new(aggregate_id) }
  let(:aggregate_id) { '204921b4-091a-41f1-85bf-126b9da585da' }

  before do
    Timecop.freeze
  end

  after do
    Timecop.return
  end

  describe '#append' do
    it 'adds to events' do
      subject.append(:something_happened)
      subject.append(:something_happened)
      expect(subject.events.size).to eq 2
    end

    it "adds aggregate id to each event's metadata" do
      subject.append(:something_happened)
      expect(subject.events.first.metadata[:aggregate_id]).to eq aggregate_id
    end
  end

  describe '#events' do
    it 'returns an empty array given no events' do
      expect(subject.events).to eq []
    end

    it 'return events in array for non-empty changeset' do
      subject.append(:something_happened)
      expect(subject.events.map(&:name)).to eq [:something_happened]
    end
  end

  describe '#empty?' do
    it 'is true for empty changeset' do
      expect(subject).to be_empty
    end

    it 'is false for changeset with events' do
      subject.append(:something_happened)
      expect(subject).to_not be_empty
    end
  end
end
