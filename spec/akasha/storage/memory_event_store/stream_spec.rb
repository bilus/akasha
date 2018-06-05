describe Akasha::Storage::MemoryEventStore::Stream do
  let(:events) do
    [
      Akasha::Event.new(:something_changed),
      Akasha::Event.new(:things_happened)
    ]
  end

  describe '#write_events' do
    it 'succeeds for empty array' do
      expect { subject.write_events([]) }.to_not raise_error
    end

    it 'succeeds for some events' do
      expect { subject.write_events(events) }.to_not raise_error
    end
  end

  describe '#read_events' do
    context 'given no block' do
      context 'with empty stream' do
        it { expect { subject.read_events(0, 100).to eq([]) } }
      end

      context 'with non-empty stream' do
        before do
          subject.write_events(events)
        end

        it 'reads a page of events from start' do
          expect { subject.read_events(0, 2).to eq(events) }
        end

        it 'reads all events from start even if too much requested' do
          expect { subject.read_events(0, 999).to eq(events) }
        end

        it 'reads events from different positions' do
          expected_first_page = [events[0]]
          expected_second_page = [events[1]]
          expected_last_page = []
          expect { subject.read_events(0, 1).to eq(expected_first_page) }
          expect { subject.read_events(1, 1).to eq(expected_second_page) }
          expect { subject.read_events(2, 1).to eq(expected_last_page) }
        end
      end
    end

    context 'given a block' do
      before do
        subject.write_events(events)
      end

      it 'reads all events from start' do
        expected_pages = [
          [events[0]],
          [events[1]]
        ]
        actual_pages = []
        subject.read_events(0, 1) do |events|
          actual_pages << events
        end
        expect(actual_pages).to eq(expected_pages)
      end

      it 'reads all events from any position' do
        expected_pages = [
          [events[1]]
        ]
        actual_pages = []
        subject.read_events(1, 1) do |events|
          actual_pages << events
        end
        expect(actual_pages).to eq(expected_pages)
      end
    end
  end
end
