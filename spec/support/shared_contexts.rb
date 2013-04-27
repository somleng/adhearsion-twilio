shared_context 'twilio' do
  include WebMockHelpers
  include ConfigHelpers

  module Adhearsion
    module Twilio
      class TestController < Adhearsion::CallController
        include Twilio::ControllerMethods

        def run
          notify_voice_request_url
        end
      end
    end
  end

  subject { Adhearsion::Twilio::TestController.new(call) }

  let(:call_params) do
    {
      :to => "85512456869",
      :from => "1000",
      :id => "5250692c-3db4-11e2-99cd-2f3f1cd7994c"
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
    set_default_config!
  end

  def stub_infinite_loop
    subject.stub(:loop).and_return(infinity.times)
  end

  def generate_erb(options = {})
    {
      :url => current_config[:voice_request_url],
      :method => current_config[:voice_request_method],
      :status_callback_url => current_config[:status_callback_url],
      :status_callback_method => current_config[:status_callback_method]
    }.merge(options)
  end

  def expect_call_status_update(options = {}, &block)
    assert_call_is_hungup unless options.delete(:hangup) == false
    cassette = options.delete(:cassette) || :hangup
    VCR.use_cassette(cassette, :erb => generate_erb(options)) do
      yield
    end
  end

  def assert_next_verb_not_reached
    # assumes next verb is <Play>
    subject.should_not_receive(:play_audio)
  end

  def assert_next_verb_reached
    # assumes next verb is <Play>
    subject.should_receive(:play_audio)
  end

  def assert_call_is_hungup
    subject.should_receive(:hangup).exactly(1).times
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
      actual_request[param].should == assertion
    end
  end
end
