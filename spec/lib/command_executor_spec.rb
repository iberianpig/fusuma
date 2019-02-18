require 'spec_helper'
# spec for CommandExecutor
module Fusuma
  RSpec.describe CommandExecutor do
    describe 'execute' do
      subject { command_executor.execute }
      let(:vector) { Plugin::Vectors::SwipeVector.new(3, 10, 5) }
      let(:command_executor) { CommandExecutor.new(vector) }
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

      before do
        allow(command_executor).to receive(:fork) do |&block|
          allow(Process).to receive(:daemon).with(true)
          allow(Process).to receive(:detach).with(anything)
          block.call
        end
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
            expect(command_executor).to receive(:exec).with('test_command')
            subject
          end
        end
        context 'with invalid condition' do
          before do
            unset_command
          end
          it 'should NOT execute command' do
            expect(command_executor).not_to receive(:exec).with('test_command')
            subject
          end
        end
      end

      context 'with shortcut' do
        before do
          unset_command
        end
        context 'with valid condition' do
          before { set_shortcut }
          after { subject }
          it 'should return' do
            expect(command_executor).to receive(:exec).with('xdotool key test+key')
          end
        end
        context 'with invalid condition' do
          before { unset_shortcut }
          after { subject }
          it 'should NOT execute shortcut' do
            expect(command_executor).not_to receive(:exec).with('xdotool key test+key')
          end
        end
      end

      context 'when any command or shortcut are not assigned' do
        before do
          unset_command
          unset_shortcut
        end
        after { subject }
        it 'should execute dummy command' do
          expect(command_executor).to receive(:exec)
            .with(%q(echo "Command is not assigned"))
        end
      end
    end
  end
end
