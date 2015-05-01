require 'adhearsion/twilio/spec/helpers'

shared_context 'twilio' do
  include Adhearsion::Twilio::Spec::Helpers

  module Adhearsion
    module Twilio
      class TestController < Adhearsion::CallController
        include Twilio::ControllerMethods

        # simulates after_end callback
        after_call do
          twilio_hangup
        end

        def run
          notify_voice_request_url
        end
      end
    end
  end

  subject { Adhearsion::Twilio::TestController.new(mock_call) }

  let(:redirect_url) { "http://localhost:3000/some_other_endpoint.xml" }
  let(:infinity) { 20 }
  let(:words) { "Hello World" }
  let(:file_url) { "http://api.twilio.com/cowbell.mp3" }

  def stub_infinite_loop
    allow(subject).to receive(:loop).and_return(infinity.times)
  end

  def assert_next_verb_not_reached
    # assumes next verb is <Play>
    expect(subject).not_to receive(:play_audio)
  end

  def assert_next_verb_reached
    # assumes next verb is <Play>
    expect(subject).to receive(:play_audio)
  end

  def assert_voice_request_params(options = {})
    position = options.delete(:request_position) || :first

    options["From"] ||= "+#{call_params[:from]}"
    options["To"] ||= "+#{call_params[:to]}"
    options["CallSid"] ||= call_params[:id]
    options["CallStatus"] ||= "in-progress"
    options["ApiVersion"] ||= "adhearsion-twilio-0.0.1"

    actual_request = request(position, :body)

    options.each do |param, assertion|
      expect(actual_request[param]).to eq(assertion)
    end
  end
end
