require 'spec_helper'
module Fusuma
  describe EventTrigger do
    describe 'exec_command' do
      subject { event_trigger.exec_command }
      let(:event_trigger) { EventTrigger.new(3, :right, :swipe) }

      context 'with command' do
        context 'with valid condition' do
          before do
            allow(Config).to receive(:command)
              .with(anything)
              .and_return('test_command')
          end
          it 'should execute command' do
            expect_any_instance_of(described_class)
              .to receive(:`)
              .with('test_command')
            subject
          end
        end
        context 'with valid condition' do
          before do
            allow(Config).to receive(:command)
              .with(anything)
              .and_return(nil)
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
        context 'with valid condition' do
          before do
            allow(Config).to receive(:shortcut)
              .with(anything)
              .and_return('test+key')
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
            allow(Config).to receive(:shortcut)
              .with(anything)
              .and_return(nil)
          end
          it 'should NOT execute shortcut' do
            expect_any_instance_of(described_class)
              .not_to receive(:`)
              .with('xdotool key test+key')
            subject
          end
        end
      end
    end
  end
end
