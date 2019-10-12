# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/config.rb'

# spec for Config
module Fusuma
  RSpec.describe Config do
    let(:keymap) do
      {
        'swipe' => {
          3 => {
            'left' => { 'command' => 'alt+Left' },
            'right' => { 'command' => 'alt+Right' }
          },
          4 => {
            'left' => { 'command' => 'super+Left' },
            'right' => { 'command' => 'super+Right' }
          }
        },
        'pinch' => {
          'in' => { 'command' => 'ctrl+plus' },
          'out' => { 'command' => 'ctrl+minus' }
        }
      }
    end

    let(:keymap_without_finger) do
      {
        'swipe' => {
          'left' => { 'command' => 'alt+Left' }
        }
      }
    end

    describe '.custom_path=' do
      before { Singleton.__init__(Config) }
      it 'should reload keymap file' do
        keymap = Config.instance.keymap
        Config.custom_path = './spec/lib/dummy_config.yml'
        custom_keymap = Config.instance.keymap
        expect(keymap).not_to eq custom_keymap
      end
    end

    describe '.search' do
      subject { Config.search(keys) }
      before do
        allow(YAML).to receive(:load_file).and_return keymap
        Config.instance.reload
      end

      context 'keys correct order' do
        let(:keys) { Config::Index.new %w[pinch in command] }
        it { is_expected.to eq 'ctrl+plus' }
      end

      context 'index include skippable key' do
        let(:keys) do
          Config::Index.new [
            Config::Index::Key.new('pinch'),
            Config::Index::Key.new(2, skippable: true),
            Config::Index::Key.new('in'),
            Config::Index::Key.new('command')
          ]
        end
        it { is_expected.to eq 'ctrl+plus' }
      end

      context 'keys incorrect order' do
        let(:keys) { Config::Index.new %w[in pinch 2 command] }
        it { is_expected.not_to eq 'ctrl+plus' }
      end
    end

    describe 'private_method: :cache' do
      it 'should cache command' do
        key   = %w[event_type finger direction command].join(',')
        value = 'shourtcut string'
        Config.instance.reload
        Config.instance.send(:cache, key) { value }
        expect(Config.instance.send(:cache, key)).to eq value
      end
    end

    describe '#reload' do
      it 'remove cached value' do
        key = 'key'
        val = 'val'
        Config.instance.send(:cache, key) { val }
        Config.instance.reload
        expect(Config.instance.send(:cache, key)).not_to eq val
        expect(Config.instance.send(:cache, key)).to eq nil
      end
    end
  end
end
