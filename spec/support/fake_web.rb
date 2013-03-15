require 'fake_web'
require 'rack/utils'

FakeWeb.allow_net_connect = false

module FakeWebHelpers
  def last_request
    FakeWeb.last_request
  end

  def last_request_body
    @last_request ||= Rack::Utils.parse_query(last_request.body)
  end
end
