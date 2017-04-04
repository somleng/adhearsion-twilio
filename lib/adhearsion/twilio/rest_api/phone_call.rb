require_relative "../util/url"

class Adhearsion::Twilio::RestApi::PhoneCall
  attr_accessor :twilio_call, :options

  def initialize(twilio_call, options = {})
    self.twilio_call = twilio_call
    self.options = options
  end

  def voice_request_url
    fetch_remote(:voice_url)
  end

  def voice_request_method
    fetch_remote(:voice_method)
  end

  def status_callback_url
    fetch_remote(:status_callback_url)
  end

  def status_callback_method
    fetch_remote(:status_callback_method)
  end

  def account_sid
    fetch_remote(:account_sid)
  end

  def auth_token
    fetch_remote(:account_auth_token)
  end

  def call_sid
    fetch_remote(:sid)
  end

  def from
    fetch_remote(:from)
  end

  def to
    fetch_remote(:to)
  end

  def twilio_request_to
    fetch_remote(:twilio_request_to)
  end

  private

  def log(*args)
    options[:logger] && options[:logger].public_send(*args)
  end

  def created?
    @remote_response && @remote_response.success?
  end

  def fetch_remote(attribute)
    (remote_response && created? && remote_response[attribute.to_s]).presence
  end

  def configuration
    @configuration ||= Adhearsion::Twilio::Configuration.new
  end

  def remote_response
    @remote_response ||= create_remote_phone_call!
  end

  def create_remote_phone_call!
    basic_auth, url = Adhearsion::Twilio::Util::Url.new(configuration.rest_api_phone_calls_url).extract_auth

    request_options = {
      :body => {
        "From" => twilio_call.from,
        "To" => twilio_call.to,
        "ExternalSid" => twilio_call.id
      }
    }

    request_options.merge!(:basic_auth => basic_auth) if basic_auth.any?

    log(:info, "POSTING to Twilio REST API at: #{url} with options: #{request_options}")

    @remote_response = HTTParty.post(url, request_options)
  end
end
