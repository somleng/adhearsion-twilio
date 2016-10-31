class Adhearsion::Twilio::Util::SipHeader
  HEADER_PREFIX = "X-Adhearsion-Twilio"

  def construct_header_name(name)
    [HEADER_PREFIX, name].join("-")
  end

  def construct_call_variable_name(name)
    construct_header_name(name).downcase.gsub('-', '_')
  end
end
