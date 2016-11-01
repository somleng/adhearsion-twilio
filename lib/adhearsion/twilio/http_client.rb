require_relative "util/url"
require_relative "util/request_validator"

class Adhearsion::Twilio::HttpClient
  CALL_STATUSES = {
    :no_answer => "no-answer",
    :answer => "completed",
    :timeout => "no-answer",
    :error => "failed",
    :in_progress => "in-progress",
    :ringing => "ringing"
  }

  CALL_DIRECTIONS = {
    :inbound => "inbound",
    :outbound_api => "outbound-api"
  }

  attr_accessor :voice_request_url,
                :voice_request_method,
                :status_callback_url,
                :status_callback_method,
                :account_sid,
                :call_sid,
                :call_direction,
                :call_from,
                :call_to,
                :auth_token,
                :logger,
                :last_request_url

  def initialize(options = {})
    self.voice_request_url = options[:voice_request_url]
    self.voice_request_method = options[:voice_request_method]
    self.status_callback_url = options[:status_callback_url]
    self.status_callback_method = options[:status_callback_method]
    self.account_sid = options[:account_sid]
    self.call_from = options[:call_from]
    self.call_to = options[:call_to]
    self.call_sid = options[:call_sid]
    self.call_direction = options[:call_direction]
    self.auth_token = options[:auth_token]
    self.logger = options[:logger]
  end

  def notify_voice_request_url
    notify_http(
      voice_request_url,
      voice_request_method,
      :ringing
    )
  end

  def notify_status_callback_url(status, options = {})
    notify_http(
      status_callback_url,
      status_callback_method,
      status,
      options,
    ) if status_callback_url.present?
  end

  def notify_http(url, method, status, options = {})
    basic_auth, sanitized_url = Adhearsion::Twilio::Util::Url.new(url).extract_auth
    self.last_request_url = sanitized_url
    request_body = {
      "CallStatus" => CALL_STATUSES[status],
    }.merge(build_request_body).merge(options)

    headers = build_twilio_signature_header(sanitized_url, request_body)
    request_options = {
      :body => request_body,
      :headers => headers
    }

    request_options.merge!(:basic_auth => basic_auth) if basic_auth.any?

    log(:info, "Notifying HTTP with method: #{method}, URL: #{sanitized_url} and options: #{request_options}")

    HTTParty.send(
      method.downcase,
      sanitized_url,
      request_options
    ).body
  end

  private

  def log(*args)
    logger && logger.public_send(*args)
  end

  def build_twilio_signature_header(url, params)
    {"X-Twilio-Signature" => twilio_request_validator.build_signature_for(url, params)}
  end

  def twilio_request_validator
    @twilio_request_validator ||= Adhearsion::Twilio::Util::RequestValidator.new(auth_token)
  end

  def api_version
    "adhearsion-twilio-#{Adhearsion::Twilio::VERSION}"
  end

  def twilio_call_direction
    CALL_DIRECTIONS[(call_direction || :inbound).to_sym]
  end

  def build_request_body
    request_options = {
      "From" => call_from,
      "To" => call_to,
      "CallSid" => call_sid,
      "Direction" => twilio_call_direction,
      "ApiVersion" => api_version
    }

    request_options.merge!("AccountSid" => account_sid) if account_sid
    request_options
  end
end
