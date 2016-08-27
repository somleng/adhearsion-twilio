require 'spec_helper'

describe Adhearsion::Twilio::ControllerMethods, :type => :call_controller do
  describe "https://demo.twilio.com/docs/voice.xml" do
    let(:cassette) { "demo.twilio.com/docs/voice.xml" }

    def assert_verb!
      expect(subject).to receive(:say)
      expect(subject).to receive(:play_audio)
    end

    def default_config
      super.merge(
        :voice_request_url => "https://demo.twilio.com/docs/voice.xml",
        :voice_request_method => :get
      )
    end

    it { run_and_assert! }
  end
end
