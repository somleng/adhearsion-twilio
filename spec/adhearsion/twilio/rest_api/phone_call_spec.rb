require 'spec_helper'

describe Adhearsion::Twilio::RestApi::PhoneCall do
  include MockCall
  include EnvHelpers

  let(:to) { "+85512234567" }
  let(:twilio_call) { Adhearsion::Twilio::Call.new(mock_call) }
  let(:phone_calls_url) { "http://39baa733-219b-406c-bc39-6befae21bbd3:559d810057b9ddaea40215ba389478ac4b25da3d49f00223d4ec1e77fe930ae9@localhost:5000/api/admin/phone_calls" }

  subject { described_class.new(twilio_call) }

  def setup_scenario
    stub_env(:ahn_twilio_rest_api_phone_calls_url => phone_calls_url)
  end

  before do
    setup_scenario
  end

  def call_params
    super.merge(:to => to)
  end

  def assert_remote_attribute!(attribute, matcher)
    expect(VCR.use_cassette(cassette) { subject.public_send(attribute) }).to matcher
    expect(subject.public_send(attribute)).to matcher
  end

  remote_attributes = [
    :voice_request_url, :voice_request_method,
    :status_callback_url, :status_callback_method,
    :auth_token, :call_sid, :to, :from, :account_sid
  ]

  context "given the phone call was successfully created on the REST API" do
    let(:cassette) { "rest_api/post_phone_calls/201_created" }

    remote_attributes.each do |remote_attribute|
      describe "##{remote_attribute}" do
        it { assert_remote_attribute!(remote_attribute, be_present) }
      end
    end
  end

  context "given the phone call was not successfully created on the REST API" do
    let(:cassette) { "rest_api/post_phone_calls/422_unprocessable_entity" }
    let(:to) { "non-existent-number" }

    remote_attributes.each do |remote_attribute|
      describe "##{remote_attribute}" do
        it { assert_remote_attribute!(remote_attribute, eq(nil)) }
      end
    end
  end
end
