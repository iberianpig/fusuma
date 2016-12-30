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
    let(:config) { Config.new }
    let(:gesture_info) { ActionStack::GestureInfo.new(@finger, @direction, @action) }

    context 'when correct keymap' do
      before do
        allow(YAML).to receive(:load_file).and_return keymap
      end

      context 'when swipe' do
        before { @action = 'swipe' }
        context 'when 3 finger' do
          before { @finger = 3 }
          it 'return swipe shourtcut' do
            @direction = 'left'
            expect(config.shortcut(gesture_info)).to eq 'alt+Left'
          end

          it 'return swipe shourtcut' do
            @direction = 'right'
            expect(config.shortcut(gesture_info)).to eq 'alt+Right'
          end
        end

        context 'when 4 finger' do
          before { @finger = 4 }
          it 'return swipe shourtcut' do
            @direction = 'left'
            expect(config.shortcut(gesture_info)).to eq 'super+Left'
          end

          it 'return swipe left shourtcut' do
            @direction = 'left'
            expect(config.shortcut(gesture_info)).to eq 'super+Left'
          end
        end
      end

      context 'when pinch' do
        before do
          @action = 'pinch'
          @finger = rand(5)
        end
        it 'return swipe shourtcut' do
          @direction = 'in'
          expect(config.shortcut(gesture_info)).to eq 'ctrl+plus'
        end

        it 'return pinch shourtcut' do
          @direction = 'out'
          expect(config.shortcut(gesture_info)).to eq 'ctrl+minus'
        end
      end
    end

    context 'when config without finger' do
      before do
        allow(YAML).to receive(:load_file).and_return keymap_without_finger
        @finger = nil
      end
      it 'return swipe shourtcut' do
        @action    = 'swipe'
        @direction = 'left'
        expect(config.shortcut(gesture_info)).to eq 'alt+Left'
      end
    end
  end
end
