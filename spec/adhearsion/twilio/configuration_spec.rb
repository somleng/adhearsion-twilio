require 'spec_helper'

describe Adhearsion::Twilio::Configuration do
  include EnvHelpers

  let(:host) { "cdn.somleng.org" }
  let(:url) { "https://#{host}/my_twiml.xml" }
  let(:http_method) { "GET" }
  let(:voice) { "arky" }

  describe "#rest_api_enabled?" do
    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_rest_api_enabled => "1")
      end

      it { is_expected.to be_rest_api_enabled }
    end

    context "by default" do
      it { is_expected.not_to be_rest_api_enabled }
    end
  end

  describe "#rest_api_phone_calls_url" do
    let(:result) { subject.rest_api_phone_calls_url }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_rest_api_phone_calls_url => url)
      end

      it { expect(result).to eq(url) }
    end

    context "by default" do
      it { expect(result).to eq(nil) }
    end
  end

  describe "#rest_api_phone_call_events_url" do
    let(:result) { subject.rest_api_phone_call_events_url }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_rest_api_phone_call_events_url => url)
      end

      it { expect(result).to eq(url) }
    end

    context "by default" do
      it { expect(result).to eq(nil) }
    end
  end

  describe "#voice_request_url" do
    let(:result) { subject.voice_request_url }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_voice_request_url => url)
      end

      it { expect(result).to eq(url) }
    end

    context "by default" do
      it { expect(result).to eq(nil) }
    end
  end

  describe "#voice_request_method" do
    let(:result) { subject.voice_request_method }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_voice_request_method => http_method)
      end

      it { expect(result).to eq(http_method) }
    end

    context "by default" do
      it { expect(result).to eq(Adhearsion::Twilio::Configuration::DEFAULT_VOICE_REQUEST_METHOD) }
    end
  end

  describe "#status_callback_url" do
    let(:result) { subject.status_callback_url }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_status_callback_url => url)
      end

      it { expect(result).to eq(url) }
    end

    context "by default" do
      it { expect(result).to eq(nil) }
    end
  end

  describe "#status_callback_method" do
    let(:result) { subject.status_callback_method }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_status_callback_method => http_method)
      end

      it { expect(result).to eq(http_method) }
    end

    context "by default" do
      it { expect(result).to eq(Adhearsion::Twilio::Configuration::DEFAULT_STATUS_CALLBACK_METHOD) }
    end
  end

  describe "#account_sid" do
    let(:result) { subject.account_sid }
    let(:account_sid) { "abcde" }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_account_sid => account_sid)
      end

      it { expect(result).to eq(account_sid) }
    end

    context "by default" do
      it { expect(result).to eq(nil) }
    end
  end

  describe "#auth_token" do
    let(:result) { subject.auth_token }
    let(:auth_token) { "abcde" }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_auth_token => auth_token)
      end

      it { expect(result).to eq(auth_token) }
    end

    context "by default" do
      it { expect(result).to eq(Adhearsion::Twilio::Configuration::DEFAULT_AUTH_TOKEN) }
    end
  end

  describe "#default_female_voice" do
    let(:result) { subject.default_female_voice }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_default_female_voice => voice)
      end

      it { expect(result).to eq(voice) }
    end

    context "by default" do
      it { expect(result).to eq(nil) }
    end
  end

  describe "#default_male_voice" do
    let(:result) { subject.default_male_voice }

    context "with global configuration" do
      before do
        stub_env(:ahn_twilio_default_male_voice => voice)
      end

      it { expect(result).to eq(voice) }
    end

    context "by default" do
      it { expect(result).to eq(nil) }
    end
  end
end
