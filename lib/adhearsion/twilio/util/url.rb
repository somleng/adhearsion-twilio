class Adhearsion::Twilio::Util::Url
  attr_accessor :url

  def initialize(url)
    self.url = url
  end

  def extract_auth
    basic_auth = {}
    uri = URI.parse(url)

    if uri.user
      basic_auth[:username] = uri.user
      basic_auth[:password] = uri.password
    end

    uri.user = nil
    uri.password = nil

    [basic_auth, uri.to_s]
  end
end
