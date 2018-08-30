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
            }
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
            'right' => {
              'shortcut' => 'alt+Right',
              'interval' => 0.3
            }
          }
        }
      }
    end

    let(:command_executor) do
      CommandExecutor.new(@finger, @vector)
    end

    describe '.shortcut' do
      context 'when keymap with finger' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap
          Config.reload
        end

        context 'when swipe' do
          before { @vector = Swipe.new(0, 0) }
          context 'when 3 finger' do
            before { @finger = 3 }
            it 'should swipe left shourtcut' do
              allow(@vector).to receive(:direction).and_return 'left'
              expect(Config.shortcut(command_executor)).to eq 'alt+Left'
            end

            it 'should swipe right shourtcut' do
              allow(@vector).to receive(:direction).and_return 'right'
              expect(Config.shortcut(command_executor)).to eq 'alt+Right'
            end
          end

          context 'when 4 finger' do
            before { @finger = 4 }
            it 'should swipe left shourtcut' do
              allow(@vector).to receive(:direction).and_return 'left'
              expect(Config.shortcut(command_executor)).to eq 'super+Left'
            end

            it 'should swipe right shourtcut' do
              allow(@vector).to receive(:direction).and_return 'right'
              expect(Config.shortcut(command_executor)).to eq 'super+Right'
            end
          end
        end

        context 'when pinch' do
          before do
            @vector = Pinch.new(0)
            @finger = rand(5)
          end
          it 'should pinch in shourtcut' do
            allow(@vector).to receive(:direction).and_return 'in'
            expect(Config.shortcut(command_executor)).to eq 'ctrl+plus'
          end

          it 'should pinch out shourtcut' do
            allow(@vector).to receive(:direction).and_return 'out'
            expect(Config.shortcut(command_executor)).to eq 'ctrl+minus'
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
          @vector = Swipe.new(0, 0)
          allow(@vector).to receive(:direction).and_return 'left'
          expect(Config.shortcut(command_executor)).to eq 'alt+Left'
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
          @vector = Swipe.new(0, 0)
          expect(Config.threshold(command_executor)).to eq 0.5
        end
      end

      context 'when threshold is set on the specific trigger' do
        before do
          allow(YAML).to receive(:load_file)
            .and_return keymap_with_trigger_threshold
          Config.reload
          @finger = 3
          @vector = Swipe.new(0, 0)
          allow(@vector).to receive(:direction).and_return 'left'
        end
        it 'should return custom threshold' do
          expect(Config.threshold(command_executor)).to eq 0.8
        end
      end

      context 'when threshold is unset' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap
          Config.reload
          @vector = Swipe.new(0, 0)
        end
        it 'should return default threshold' do
          expect(Config.threshold(command_executor)).to eq 1
        end
      end

      context 'with irregular event_type' do
        it 'should return default threshold' do
          @vector = Swipe.new(0, 0)
          event_type = 'missing_property'
          allow(command_executor).to receive(:event_type).and_return event_type
          expect(Config.threshold(command_executor)).to eq 1
        end
      end
    end

    describe '.interval' do
      context 'when interval is set to keymap' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap_with_interval
          Config.reload
          @vector = Swipe.new(0, 0)
        end
        it 'should return custom interval' do
          expect(Config.interval(command_executor)).to eq 0.3
        end
      end

      context 'when interval is set on the specific trigger' do
        before do
          allow(YAML).to receive(:load_file)
            .and_return keymap_with_trigger_interval
          Config.reload
          @finger = 4
          @vector = Swipe.new(0, 0)
          allow(@vector).to receive(:direction).and_return 'right'
        end
        it 'should return custom interval' do
          expect(Config.interval(command_executor)).to eq 0.3
        end
      end

      context 'when interval is unset' do
        before do
          allow(YAML).to receive(:load_file).and_return keymap
          Config.reload
          @vector = Swipe.new(0, 0)
        end
        it 'should return default interval' do
          expect(Config.threshold(command_executor)).to eq 1
        end
      end

      context 'with irregular event_type' do
        it 'should return default interval' do
          @vector = Swipe.new(0, 0)
          event_type = 'missing_property'
          allow(command_executor).to receive(:event_type).and_return event_type
          expect(Config.threshold(command_executor)).to eq 1
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
        key   = %w[event_type finger direction shortcut].join(',')
        value = 'shourtcut string'
        Config.reload
        Config.instance.send(:cache, key) { value }
        expect(Config.instance.send(:cache, key)).to eq value
      end
    end
  end
end
