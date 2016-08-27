module CallControllerHelpers
  def subject
    @subject ||= Adhearsion::Twilio::TestController.new(mock_call, metadata)
  end

  def metadata
    @metadata
  end

  def redirect_url
    @redirect_url ||= "http://localhost:3000/some_other_endpoint.xml"
  end

  def infinity
    @infinity ||= 20
  end

  def words
    @words ||= "Hello World"
  end

  def file_url
    @file_url ||= "http://api.twilio.com/cowbell.mp3"
  end

  def stub_infinite_loop
    allow(subject).to receive(:loop).and_return(infinity.times)
  end

  def assert_next_verb_not_reached!
    # assumes next verb is <Play>
    expect(subject).not_to receive(:play_audio)
  end

  def assert_next_verb_reached!
    # assumes next verb is <Play>
    expect(subject).to receive(:play_audio)
  end

  def call_params
    @call_params ||= {
      :to => "85512456869",
      :from => "1000",
      :id => "5250692c-3db4-11e2-99cd-2f3f1cd7994c"
    }
  end

  def mock_call
    @mock_call ||= double(
      "Call",
      :from => "Extension 1000 <#{call_params[:from]}@192.168.42.234>",
      :to => "#{call_params[:to]}@192.168.42.234",
      :id => call_params[:id]
    )
  end

  def expect_call_status_update(options = {}, &block)
    assert_call_controller_assertions!
    cassette = options.delete(:cassette) || :hangup
    VCR.use_cassette(cassette, :erb => generate_erb(options)) do
      yield
    end
    assert_requests!
  end

  def assert_call_controller_assertions!
    assert_answered!
    assert_hungup!
    assert_verb!
  end

  def assert_verb!
    expect(subject).to receive(asserted_verb).with(*asserted_verb_args).exactly(asserted_verb_num_runs).times
  end

  def assert_requests!
  end

  def asserted_verb_num_runs
    1
  end

  def asserted_verb_args
    []
  end

  def asserted_verb_options
    {}
  end

  def asserted_verb
  end

  def assert_hungup!
    expect(subject).to receive(:hangup).exactly(1).times
  end

  def assert_answered!
    expect(subject).to receive(:answer).exactly(1).times
  end

  def generate_erb(options = {})
    {
      :url => current_config[:voice_request_url],
      :method => current_config[:voice_request_method].presence || "post",
      :status_callback_url => current_config[:status_callback_url],
      :status_callback_method => current_config[:status_callback_method].presence || "post"
    }.merge(options)
  end

  def cassette_options
    {:cassette => cassette}
  end

  def cassette
  end

  def run_and_assert!
    expect_call_status_update(cassette_options) { run! }
  end

  def run!
    subject.run
  end

  def default_config
    {
      :voice_request_url => "http://localhost:3000/",
      :voice_request_method => :post,
      :status_callback_url => nil,
      :status_callback_method => nil,
      :default_male_voice => nil,
      :default_female_voice => nil
    }
  end

  def current_config
    current_config = {}
    default_config.each do |config, value|
      current_config[config] = ENV["AHN_TWILIO_#{config.to_s.upcase}"]
    end
    current_config
  end

  def set_default_config!
    default_config.each do |config, value|
      ENV["AHN_TWILIO_#{config.to_s.upcase}"] = value.to_s
    end
  end

  def set_dummy_url_config(url_type, url_config, value)
    ENV["AHN_TWILIO_#{url_type.to_s.upcase}_#{url_config.to_s.upcase}"] = value.to_s
  end

  def set_dummy_voices
    ENV["AHN_TWILIO_DEFAULT_MALE_VOICE"] = "default_male_voice"
    ENV["AHN_TWILIO_DEFAULT_FEMALE_VOICE"] = "default_female_voice"
  end

  def stub_call_controller!
    allow(subject).to receive(:hangup)
    allow(subject).to receive(:answer)
    allow(subject).to receive(:reject)
    allow(subject).to receive(:sleep)
  end

  def stub_mock_call!
    allow(mock_call).to receive(:alive?)
    allow(mock_call).to receive(:async).and_return(mock_call)
    allow(mock_call).to receive(:register_controller)
    allow(mock_call).to receive(:duration)
    allow(mock_call).to receive(:on_end)
  end
end

RSpec.configure do |config|
  config.include(CallControllerHelpers, :type => :call_controller)

  config.before(:type => :call_controller) do
    WebMock.clear_requests!
    stub_call_controller!
    stub_mock_call!
    set_default_config!
  end
end
