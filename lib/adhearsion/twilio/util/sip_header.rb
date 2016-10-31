class Adhearsion::Twilio::Util::SipHeader
  HEADER_PREFIX = "X-Adhearsion-Twilio"

  def construct_header_name(name)
    [HEADER_PREFIX, name].join("-")
  end
end
