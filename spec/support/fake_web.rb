require 'fake_web'
require 'rack/utils'

FakeWeb.allow_net_connect = false

module FakeWebHelpers
  def last_request
    @last_request ||= Rack::Utils.parse_query(FakeWeb.last_request.body)
  end
end
