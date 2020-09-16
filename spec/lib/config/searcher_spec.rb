# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/config.rb'
require './lib/fusuma/config/searcher.rb'

# spec for Config
module Fusuma
  RSpec.describe Config::Searcher do
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
      let(:index) { nil }
      subject { Config::Searcher.new.search(index, location: Config.instance.keymap) }
      before do
        allow(YAML).to receive(:load_file).and_return keymap
        Config.instance.reload
      end

      context 'index correct order' do
        let(:index) { Config::Index.new %w[pinch in command] }
        it { is_expected.to eq 'ctrl+plus' }
      end

      context 'index include skippable key' do
        let(:index) do
          Config::Index.new [
            Config::Index::Key.new('pinch'),
            Config::Index::Key.new(2, skippable: true),
            Config::Index::Key.new('out'),
            Config::Index::Key.new('command')
          ]
        end
        it { expect(Config::Searcher.skip { subject }).to eq 'ctrl+minus' }
      end

      context 'index include skippable key at first' do
        let(:index) do
          Config::Index.new [
            Config::Index::Key.new(:hoge, skippable: true),
            Config::Index::Key.new(:fuga, skippable: true),
            Config::Index::Key.new('pinch'),
            Config::Index::Key.new('in'),
            Config::Index::Key.new(:piyo, skippable: true),
            Config::Index::Key.new('command')
          ]
        end
        it { expect(Config::Searcher.skip { subject }).to eq 'ctrl+plus' }
      end

      context 'index incorrect order' do
        let(:index) { Config::Index.new %w[in pinch 2 command] }
        it { is_expected.not_to eq 'ctrl+plus' }
      end
    end

    describe 'private_method: :cache' do
      it 'should cache command' do
        key   = %w[event_type finger direction command].join(',')
        value = 'shourtcut string'
        searcher = Config::Searcher.new
        searcher.send(:cache, key) { value }
        expect(searcher.send(:cache, key)).to eq value
      end
    end

    describe '#validate' do
      context 'with valid yaml' do
        before do
          string = <<~CONFIG
            swipe:
              3:
                left:
                  command: echo 'swipe left'

          CONFIG
          @file_path = Tempfile.open do |temp_file|
            temp_file.tap { |f| f.write(string) }
          end
        end

        it 'should return Hash' do
          Config.instance.validate(@file_path)
        end
      end

      context 'with invalid yaml' do
        before do
          string = <<~CONFIG
            this is not yaml
          CONFIG
          @file_path = Tempfile.open do |temp_file|
            temp_file.tap { |f| f.write(string) }
          end
        end

        it 'raise InvalidFileError' do
          expect { Config.instance.validate(@file_path) }.to raise_error(Config::InvalidFileError)
        end

        context 'with duplicated key' do
          before do
            string = <<~CONFIG
              pinch:
                2:
                  in:
                    command: "xdotool keydown ctrl click 4 keyup ctrl" # threshold: 0.5, interval: 0.5
                2:
                  out:
                    command: "xdotool keydown ctrl click 5 keyup ctrl" # threshold: 0.5, interval: 0.5
            CONFIG
            @file_path = Tempfile.open do |temp_file|
              temp_file.tap { |f| f.write(string) }
            end
          end

          it 'raise InvalidFileError' do
            expect { Config.instance.validate(@file_path) }.to raise_error(Config::InvalidFileError)
          end
        end
      end
    end
  end
end
