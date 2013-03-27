require 'webmock/rspec'
require 'rack/utils'

WebMock.disable_net_connect!

# From: https://gist.github.com/2596158
# Thankyou Bartosz Blimke!
# https://twitter.com/bartoszblimke/status/198391214247124993

module LastRequest
  def clear_requests!
    @requests = nil
  end

  def requests
    @requests ||= []
  end

  def last_request=(request_signature)
    requests << request_signature
    request_signature
  end
end

module WebMockHelpers
  def requests
    requests = WebMock.requests
  end

  def first_request(attribute = nil)
    request(:first, attribute)
  end

  def last_request(attribute = nil)
    request(:last, attribute)
  end

  private

  def request(position, attribute = nil)
    request = WebMock.requests.send(position)

    case attribute
    when :body
      Rack::Utils.parse_query(request.body)
    when :url
     request.uri.to_s
    when :method
      request.method
    else
      request
    end
  end
end

WebMock.extend(LastRequest)
WebMock.after_request do |request_signature, response|
  WebMock.last_request = request_signature
end

RSpec.configure do |config|
  config.before do
    WebMock.clear_requests!
  end
end
