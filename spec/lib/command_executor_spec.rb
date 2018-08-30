require 'spec_helper'
# spec for CommandExecutor
module Fusuma
  describe CommandExecutor do
    describe 'execute' do
      subject { command_executor.execute }
      let(:vector) { Swipe.new(10, 5) }
      let(:command_executor) { CommandExecutor.new(3, vector) }
      let(:set_command) do
        allow(Config).to receive(:command)
          .with(anything)
          .and_return('test_command')
      end
      let(:unset_command) do
        allow(Config).to receive(:command)
          .with(anything)
          .and_return(nil)
      end
      let(:set_shortcut) do
        allow(Config).to receive(:shortcut)
          .with(anything)
          .and_return('test+key')
      end
      let(:unset_shortcut) do
        allow(Config).to receive(:shortcut)
          .with(anything)
          .and_return(nil)
      end

      context 'with command' do
        before do
          unset_shortcut
        end
        context 'with valid condition' do
          before do
            set_command
          end
          it 'should execute command' do
            expect_any_instance_of(described_class)
              .to receive(:`)
              .with('test_command')
            subject
          end
        end
        context 'with invalid condition' do
          before do
            unset_command
          end
          it 'should NOT execute command' do
            expect_any_instance_of(described_class)
              .not_to receive(:`)
              .with('test_command')
            subject
          end
        end
      end

      context 'with shortcut' do
        before do
          unset_command
        end
        context 'with valid condition' do
          before do
            set_shortcut
          end
          it 'should return' do
            expect_any_instance_of(described_class)
              .to receive(:`)
              .with('xdotool key test+key')
            subject
          end
        end
        context 'with invalid condition' do
          before do
            unset_shortcut
          end
          it 'should NOT execute shortcut' do
            expect_any_instance_of(described_class)
              .not_to receive(:`)
              .with('xdotool key test+key')
            subject
          end
        end
      end

      context 'when any command or shortcut are not assigned' do
        before do
          unset_command
          unset_shortcut
        end
        it 'should NOT execute command' do
          expect_any_instance_of(described_class)
            .not_to receive(:`)
            .with(%q('echo "Command is not assigned"'))
          subject
        end
      end
    end
  end
end
