describe Akasha::Event do
  let(:event) { described_class.new(:post_created, id, foo: 'bar') }
  let(:id) { '49a122d1-6cbb-490c-857b-ebf473032bc5' }
  let(:now) { Time.now.utc }

  describe '#==' do
    subject { event }
    let(:identical) { described_class.new(:post_created, id, foo: 'bar') }
    let(:different_name) { described_class.new(:post_deleted, id, foo: 'bar') }
    let(:different_data) { described_class.new(:post_created, id, foo: 'NOT BAR') }
    let(:identical) { described_class.new(:post_created, id, foo: 'bar') }
    let(:different_metadata) { described_class.new(:post_created, id, { baz: 'qux' }, foo: 'bar') }

    it { is_expected.to eq(subject) }
    it { is_expected.to eq(identical) }
    it { is_expected.to_not eq(different_name) }
    it { is_expected.to_not eq(different_data) }
    it { is_expected.to_not eq(different_metadata) }
  end

  describe '#metadata' do
    subject { event.metadata }

    it { is_expected.to be_a Hash }
  end
end
