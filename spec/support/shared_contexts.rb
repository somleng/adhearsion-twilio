shared_context 'twilio' do
  include WebMockHelpers

  module Adhearsion
    module Twilio
      class TestController < Adhearsion::CallController
        include Twilio::ControllerMethods

        def run
          redirect
        end
      end
    end
  end

  subject { Adhearsion::Twilio::TestController.new(call) }

  let(:call_params) do
    {
      :to => "85512456869",
      :from => "1000",
      :id => "5150691c-3db4-11e2-99cd-1f3f1cd7995d"
    }
  end

  let(:call) do
    mock(
      "Call",
      :from => "Extension 1000 <#{call_params[:from]}@192.168.42.234>",
      :to => "#{call_params[:to]}@192.168.42.234",
      :id => call_params[:id]
    )
  end

  let(:redirect_url) { "http://localhost:3000/some_other_endpoint.xml" }
  let(:infinity) { 20 }
  let(:words) { "Hello World" }
  let(:file_url) { "http://api.twilio.com/cowbell.mp3" }

  before do
    subject.stub(:hangup)
    call.stub(:alive?)
  end

  def set_default_voices
    ENV["AHN_TWILIO_DEFAULT_MALE_VOICE"] = "default_male_voice"
    ENV["AHN_TWILIO_DEFAULT_FEMALE_VOICE"] = "default_female_voice"
  end

  def stub_infinite_loop
    subject.stub(:loop).and_return(infinity.times)
  end

  def default_config
    {
      :voice_request_url => ENV["AHN_TWILIO_VOICE_REQUEST_URL"] || "http://localhost:3000/",
      :voice_request_method => ENV["AHN_TWILIO_VOICE_REQUEST_METHOD"] || :post,
      :default_male_voice => ENV["AHN_TWILIO_DEFAULT_MALE_VOICE"],
      :default_female_voice => ENV["AHN_TWILIO_DEFAULT_FEMALE_VOICE"]
    }
  end

  def generate_erb(options = {})
    {
      :url => default_config[:voice_request_url],
      :method => default_config[:voice_request_method]
    }.merge(options)
  end

  def expect_call_status_update(options = {}, &block)
    cassette = options.delete(:cassette) || :hangup
    VCR.use_cassette(cassette, :erb => generate_erb(options)) do
      yield
    end
  end

  def assert_voice_request_params(options = {})
    options["From"] ||= "+#{call_params[:from]}"
    options["To"] ||= "+#{call_params[:to]}"
    options["CallSid"] ||= call_params[:id]
    options["CallStatus"] ||= "in-progress"

    last_request(:body).each do |param, value|
      value.should == options[param]
    end
  end
end
