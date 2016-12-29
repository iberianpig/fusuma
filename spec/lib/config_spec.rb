require 'spec_helper'

describe Fusuma::Config do
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
  let(:config) { Fusuma::Config.new }

  before do
    allow(YAML).to receive(:load_file).and_return keymap
  end

  context 'when 3 finger' do
    before { @finger = 3 }
    it 'return swipe shourtcut' do
      expect(config.shortcut('swipe', 'left', @finger)).to eq 'alt+Left'
    end

    it 'return swipe shourtcut' do
      expect(config.shortcut('swipe', 'right', @finger)).to eq 'alt+Right'
    end
  end

  context 'when 4 finger' do
    before { @finger = 4 }
    it 'return swipe shourtcut' do
      expect(config.shortcut('swipe', 'left', @finger)).to eq 'super+Left'
    end

    it 'return swipe shourtcut' do
      expect(config.shortcut('swipe', 'right', @finger)).to eq 'super+Right'
    end
  end

  context 'when pinch' do
    it 'return swipe shourtcut' do
      expect(config.shortcut('pinch', 'in', @finger)).to eq 'ctrl+plus'
    end

    it 'return swipe shourtcut' do
      expect(config.shortcut('pinch', 'out', @finger)).to eq 'ctrl+minus'
    end
  end
end
