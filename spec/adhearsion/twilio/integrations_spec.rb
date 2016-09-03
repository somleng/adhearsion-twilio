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

  describe "https://github.com/dwilkie/adhearsion-twilio/issues/11" do
    let(:cassette) { "gist.githubusercontent.com/dwilkie/77a90816dbc241e4dec9575ffff5f2db/raw/773e4394ae32332dde663b7a8ac8079c5771d5b6/testtwiml.xml" }

    def assert_verb!
      expect(subject).to receive(:play_audio)
    end

    def default_config
      super.merge(
        :voice_request_url => "https://gist.githubusercontent.com/dwilkie/77a90816dbc241e4dec9575ffff5f2db/raw/773e4394ae32332dde663b7a8ac8079c5771d5b6/testtwiml.xml",
        :voice_request_method => :get
      )
    end

    it { run_and_assert! }
  end
end
