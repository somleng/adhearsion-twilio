require 'spec_helper'

describe Adhearsion::Twilio::RestApi::PhoneCall do
  include MockCall
  include EnvHelpers

  let(:to) { "+85512234567" }
  let(:twilio_call) { Adhearsion::Twilio::Call.new(mock_call) }
  let(:phone_calls_url) { "http://ad2dae01-81da-4183-9c82-3b2e7c19a954:d6203008c04ff84647e0ab61ff3f9d47179687ff3f7cedb0cd0d533cecad1f7c@localhost:3000/api/admin/phone_calls" }

  let(:remote_request) { WebMock.requests.last }
  let(:remote_request_body) { WebMock.request_params(remote_request) }

  subject { described_class.new(:twilio_call => twilio_call) }

  def setup_scenario
    stub_env(:ahn_twilio_rest_api_phone_calls_url => phone_calls_url)
  end

  before do
    setup_scenario
  end

  def call_params
    super.merge(:to => to)
  end

  def asserted_request_variables
    {
      "sip_from_host" => call_params[:variables]["variable_sip_from_host"],
      "sip_to_host" => call_params[:variables]["variable_sip_to_host"],
      "sip_network_ip" => call_params[:variables]["variable_sip_network_ip"]
    }
  end

  def assert_remote_attribute!(attribute, matcher)
    expect(VCR.use_cassette(cassette) { subject.public_send(attribute) }).to matcher
    expect(remote_request_body["Variables"]).to eq(asserted_request_variables)
    expect(subject.public_send(attribute)).to matcher
  end

  remote_attributes = [
    :voice_request_url, :voice_request_method,
    :auth_token, :call_sid, :to, :from, :account_sid,
    :twilio_request_to, :direction, :api_version
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
