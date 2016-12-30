require 'spec_helper'

module Fusuma
  describe Config do
    let(:keymap) do
      {
        'swipe' => {
          3 => {
            'left'  => { 'shortcut' => 'alt+Left' },
            'right' => {
              'shortcut'  => 'alt+Right',
              'threshold' => 0.5
            }
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

    let(:config) { Config.new }

    let(:gesture_info) do
      ActionStack::GestureInfo.new(@finger, @direction, @action)
    end

    context 'when keymap with finger' do
      before do
        allow(YAML).to receive(:load_file).and_return keymap
      end

      context 'when swipe' do
        before { @action = 'swipe' }
        context 'when 3 finger' do
          before { @finger = 3 }
          it 'should swipe left shourtcut' do
            @direction = 'left'
            expect(config.shortcut(gesture_info)).to eq 'alt+Left'
          end

          it 'should swipe right shourtcut' do
            @direction = 'right'
            expect(config.shortcut(gesture_info)).to eq 'alt+Right'
          end
        end

        context 'when 4 finger' do
          before { @finger = 4 }
          it 'should swipe left shourtcut' do
            @direction = 'left'
            expect(config.shortcut(gesture_info)).to eq 'super+Left'
          end

          it 'should swipe right shourtcut' do
            @direction = 'right'
            expect(config.shortcut(gesture_info)).to eq 'super+Right'
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
          expect(config.shortcut(gesture_info)).to eq 'ctrl+plus'
        end

        it 'should pinch out shourtcut' do
          @direction = 'out'
          expect(config.shortcut(gesture_info)).to eq 'ctrl+minus'
        end
      end

      it 'should return threshold' do
        @action    = 'swipe'
        @finger    = 3
        @direction = 'right'
        expect(config.threshold(gesture_info)).to eq 0.5
      end
      it 'should not return threshold' do
        @action    = 'swipe'
        @finger    = 3
        @direction = 'left'
        expect(config.threshold(gesture_info)).to eq nil
      end
    end

    context 'when keymap without finger' do
      before do
        allow(YAML).to receive(:load_file).and_return keymap_without_finger
        @finger = nil
      end
      it 'should swipe shourtcut' do
        @action    = 'swipe'
        @direction = 'left'
        expect(config.shortcut(gesture_info)).to eq 'alt+Left'
      end
    end

    it 'should cache shortcut' do
      key = %w(action_type finger direction shortcut).join(',')
      value = 'shourtcut string'
      config.send(:cache, key) { value }
      expect(config.send(:cache, key)).to eq value
    end
  end
end
