require "spec_helper"

describe Adhearsion::Twilio::ControllerMethods, type: :call_controller, include_deprecated_helpers: true do
  describe "#register_event_handlers" do
    def setup_scenario
      allow(mock_call).to receive(:register_event_handler)
      expect(mock_call).to receive(:register_event_handler).with(Adhearsion::Event::Ringing)
      expect(mock_call).to receive(:register_event_handler).with(Adhearsion::Event::Answered)
      expect(mock_call).to receive(:register_event_handler).with(Adhearsion::Event::End)
      expect(mock_call).to receive(:register_event_handler).with(Adhearsion::Event::Complete)
      subject.send(:register_event_handlers)
    end

    before do
      setup_scenario
    end

    def assert_register_event_handlers!; end

    it { assert_register_event_handlers! }
  end
end
