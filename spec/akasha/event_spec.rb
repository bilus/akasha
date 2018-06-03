describe Akasha::Event do
  describe '#==' do
    subject { described_class.new(:post_created, now, foo: 'bar') }
    let(:now) { Time.now }
    let(:identical) { described_class.new(:post_created, now, foo: 'bar') }
    let(:different_name) { described_class.new(:post_deleted, now, foo: 'bar') }
    let(:different_data) { described_class.new(:post_created, now, foo: 'NOT BAR') }
    let(:identical) { described_class.new(:post_created, now, foo: 'bar') }
    let(:different_creation_time) { described_class.new(:post_created, now - 1, foo: 'bar') }

    it { is_expected.to eq(subject) }
    it { is_expected.to eq(identical) }
    it { is_expected.to_not eq(different_name) }
    it { is_expected.to_not eq(different_data) }
    it { is_expected.to_not eq(different_creation_time) }
  end
end
