describe Akasha::Event do
  subject { described_class.new(:post_created, id, now, foo: 'bar') }
  let(:id) { '49a122d1-6cbb-490c-857b-ebf473032bc5' }
  let(:now) { Time.now.utc }

  describe '#==' do
    let(:identical) { described_class.new(:post_created, id, now, foo: 'bar') }
    let(:different_name) { described_class.new(:post_deleted, id, now, foo: 'bar') }
    let(:different_data) { described_class.new(:post_created, id, now, foo: 'NOT BAR') }
    let(:identical) { described_class.new(:post_created, id, now, foo: 'bar') }
    let(:different_creation_time) { described_class.new(:post_created, id, now - 1, foo: 'bar') }

    it { is_expected.to eq(subject) }
    it { is_expected.to eq(identical) }
    it { is_expected.to_not eq(different_name) }
    it { is_expected.to_not eq(different_data) }
    it { is_expected.to_not eq(different_creation_time) }
  end
end
