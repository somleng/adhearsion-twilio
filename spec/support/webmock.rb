require 'webmock/rspec'
require 'rack/utils'

WebMock.disable_net_connect!

# From: https://gist.github.com/2596158
# Thankyou Bartosz Blimke!
# https://twitter.com/bartoszblimke/status/198391214247124993

module LastRequest
  def last_request
    @last_request
  end

  def last_request=(request_signature)
    @last_request = request_signature
  end
end

module WebMockHelpers
  def last_request(attribute)
    request = WebMock.last_request

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
