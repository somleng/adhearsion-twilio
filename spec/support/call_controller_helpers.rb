require_relative "env_helpers"

module CallControllerHelpers
  include EnvHelpers

  def generate_cassette_erb(options = {})
    options.reverse_merge(
      url: ENV.fetch("AHN_TWILIO_VOICE_REQUEST_URL"),
      method: ENV.fetch("AHN_TWILIO_VOICE_REQUEST_METHOD")
    )
  end

  def build_controller(options = {})
    call = options.delete(:call) || build_fake_call
    controller = Adhearsion::Twilio::TestController.new(call, options.delete(:metadata))
    (%i[hangup answer reject sleep] + Array(options[:allow])).each do |arg|
      allow(controller).to receive(arg)
    end
    controller
  end

  def build_fake_call(options = {})
    variables = options.fetch(:variables) do
      {
        "variable_sip_from_host" => "192.168.1.1",
        "variable_sip_to_host" => "192.168.2.1",
        "variable_sip_network_ip" => "192.168.3.1"
      }
    end

    fake_call = instance_spy(
      Adhearsion::Call,
      from: "Extension 1000 <#{options.fetch(:from) { '1000' }}@192.168.42.234>",
      to: "#{options.fetch(:to) { '85512456869' }}@192.168.42.234",
      id: options.fetch(:id) { SecureRandom.uuid },
      variables: variables
    )

    fake_call
  end

  def stub_default_env(options = {})
    stub_env(
      options.reverse_merge(
        ahn_twilio_voice_request_url: "https://scfm.somleng.org/api/remote_phone_call_events",
        ahn_twilio_voice_request_method: :post
      )
    )
  end

  def silence_logging!
    Adhearsion::Logging.silence!
  end
end

RSpec.configure do |config|
  config.include(CallControllerHelpers, type: :call_controller)

  config.before(type: :call_controller) do
    WebMock.clear_requests!
    stub_default_env
    silence_logging!
  end
end
