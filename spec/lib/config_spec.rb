require 'spec_helper'

module Fusuma
  describe Config do
    let(:keymap) do
      {
        'swipe' => {
          3 => {
            'left'  => { 'shortcut' => 'alt+Left' },
            'right' => { 'shortcut' => 'alt+Right' }
          },
          4 => {
            'left'  => { 'shortcut' => 'super+Left' },
            'right' => { 'shortcut' => 'super+Right' }
          }
        },
        'pinch' => {
          'in'  => { 'shortcut' => 'ctrl+plus' },
          'out' => { 'shortcut' => 'ctrl+minus' }
        }
      }
    end

    let(:keymap_without_finger) do
      {
        'swipe' => {
          'left' => { 'shortcut' => 'alt+Left' }
        }
      }
    end

    let(:keymap_with_threshold) do
      {
        'threshold' => {
          'swipe' => 0.5,
          'pinch' => 2
        }
      }
    end

    let(:keymap_with_trigger_threshold) do
      {
        'swipe' => {
          3 => {
            'left' => {
              'shortcut' => 'alt+Left',
              'threshold' => 0.8
            },
          }
        }
      }
    end

    let(:keymap_with_interval) do
      {
        'interval' => {
          'swipe' => 0.3,
          'pinch' => 0.5
        }
      }
    end

    let(:keymap_with_trigger_interval) do
      {
        'swipe' => {
          4 => {
            'right'  => {
              'shortcut' => 'alt+Right',
              'interval' => 0.3
            },
          }
        }
      }
    end

    let(:event_trigger) do
      EventTrigger.new(@finger, @direction, @action)
    end

    describe '.shortcut' do
      context 'when keymap with finger' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap
          Config.reload
        end

        context 'when swipe' do
          before { @action = 'swipe' }
          context 'when 3 finger' do
            before { @finger = 3 }
            it 'should swipe left shourtcut' do
              @direction = 'left'
              expect(Config.shortcut(event_trigger)).to eq 'alt+Left'
            end

            it 'should swipe right shourtcut' do
              @direction = 'right'
              expect(Config.shortcut(event_trigger)).to eq 'alt+Right'
            end
          end

          context 'when 4 finger' do
            before { @finger = 4 }
            it 'should swipe left shourtcut' do
              @direction = 'left'
              expect(Config.shortcut(event_trigger)).to eq 'super+Left'
            end

            it 'should swipe right shourtcut' do
              @direction = 'right'
              expect(Config.shortcut(event_trigger)).to eq 'super+Right'
            end
          end
        end

        context 'when pinch' do
          before do
            @action = 'pinch'
            @finger = rand(5)
          end
          it 'should pinch in shourtcut' do
            @direction = 'in'
            expect(Config.shortcut(event_trigger)).to eq 'ctrl+plus'
          end

          it 'should pinch out shourtcut' do
            @direction = 'out'
            expect(Config.shortcut(event_trigger)).to eq 'ctrl+minus'
          end
        end
      end

      context 'when keymap without finger' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap_without_finger
          Config.reload
          @finger = nil
        end
        it 'should swipe shourtcut' do
          @action    = 'swipe'
          @direction = 'left'
          expect(Config.shortcut(event_trigger)).to eq 'alt+Left'
        end
      end
    end

    describe '.threshold' do
      context 'when threshold is set to keymap' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap_with_threshold
          Config.reload
        end
        it 'should return custom threshold' do
          action_type = 'swipe'
          expect(Config.threshold(action_type, event_trigger)).to eq 0.5
        end
      end

      context 'when threshold is set on the trigger' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap_with_trigger_threshold
          Config.reload
          @finger    = 3
          @action    = 'swipe'
          @direction = 'left'
        end
        it 'should return custom threshold' do
          action_type = 'swipe'
          expect(Config.threshold(action_type, event_trigger)).to eq 0.8
        end
      end

      context 'when threshold is unset' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap
          Config.reload
        end
        it 'should return default threshold' do
          action_type = 'swipe'
          expect(Config.threshold(action_type, event_trigger)).to eq 1
        end
      end

      context 'with irregular action_type' do
        it 'should return default threshold' do
          action_type = 'missing_property'
          expect(Config.threshold(action_type, event_trigger)).to eq 1
        end
      end
    end

    describe '.interval' do
      context 'when interval is set to keymap' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap_with_interval
          Config.reload
        end
        it 'should return custom interval' do
          action_type = 'swipe'
          expect(Config.interval(action_type, event_trigger)).to eq 0.3
        end
      end

      context 'when interval is set on the trigger' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap_with_trigger_interval
          Config.reload
          @finger    = 4
          @action    = 'swipe'
          @direction = 'right'
        end
        it 'should return custom interval' do
          action_type = 'swipe'
          expect(Config.interval(action_type, event_trigger)).to eq 0.3
        end
      end

      context 'when interval is unset' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap
          Config.reload
        end
        it 'should return default interval' do
          action_type = 'swipe'
          expect(Config.threshold(action_type, event_trigger)).to eq 1
        end
      end

      context 'with irregular action_type' do
        it 'should return default interval' do
          action_type = 'missing_property'
          expect(Config.threshold(action_type, event_trigger)).to eq 1
        end
      end
    end

    describe '.reload' do
      it 'should reload keymap file' do
        Config.reload
        allow(YAML).to receive(:load_file).and_return keymap
        keymap = Config.reload.keymap
        allow(YAML).to receive(:load_file).and_return keymap_with_threshold
        reloaded_keymap = Config.reload.keymap
        expect(keymap).not_to eq reloaded_keymap
      end
      it 'remove cached value' do
        key = 'key'
        val = 'val'
        Config.instance.send(:cache, key) { val }
        Config.reload
        expect(Config.instance.send(:cache, key)).not_to eq val
        expect(Config.instance.send(:cache, key)).to eq nil
      end
    end

    describe 'private_method: :cache' do
      it 'should cache shortcut' do
        key   = %w[action_type finger direction shortcut].join(',')
        value = 'shourtcut string'
        Config.reload
        Config.instance.send(:cache, key) { value }
        expect(Config.instance.send(:cache, key)).to eq value
      end
    end
  end
end
