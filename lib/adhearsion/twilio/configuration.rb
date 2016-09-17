class Adhearsion::Twilio::Configuration
  DEFAULT_AUTH_TOKEN = "ADHEARSION_TWILIO_AUTH_TOKEN"
  DEFAULT_VOICE_REQUEST_METHOD = "POST"
  DEFAULT_STATUS_CALLBACK_METHOD = "POST"

  attr_accessor :metadata

  def initialize(metadata)
    self.metadata = metadata
  end

  def voice_request_url
    metadata[:voice_request_url] || config.voice_request_url
  end

  def voice_request_method
    metadata[:voice_request_method] || config.voice_request_method.presence || DEFAULT_VOICE_REQUEST_METHOD
  end

  def status_callback_url
    metadata[:status_callback_url] || config.status_callback_url
  end

  def status_callback_method
    metadata[:status_callback_method] || config.status_callback_method.presence || DEFAULT_STATUS_CALLBACK_METHOD
  end

  def auth_token
    metadata[:auth_token] || config.auth_token || DEFAULT_AUTH_TOKEN
  end

  def default_female_voice
    config.default_female_voice
  end

  def default_male_voice
    config.default_male_voice
  end

  private

  def config
    Adhearsion.config[:twilio]
  end
end
