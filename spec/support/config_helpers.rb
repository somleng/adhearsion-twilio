module ConfigHelpers
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
end
