require 'spec_helper'

describe Adhearsion::Twilio::Util::RequestValidator do
  let(:auth_token) { '2bd9e9638872de601313dc77410d3b23' }
  subject { described_class.new(auth_token) }

  describe "configuration" do
    it { expect(subject.instance_variable_get('@auth_token')).to eq(auth_token) }

    context "passing nil" do
      let(:auth_token) { nil }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end

  describe "validations" do
    let(:url) { 'http://twiliotests.heroku.com/validate/voice' }

    let(:params) do
      {
        'ToState' => 'California',
        'CalledState' => 'California',
        'Direction' => 'inbound',
        'FromState' => 'CA',
        'AccountSid' => 'ACba8bc05eacf94afdae398e642c9cc32d',
        'Caller' => '+14153595711',
        'CallerZip' => '94108',
        'CallerCountry' => 'US',
        'From' => '+14153595711',
        'FromCity' => 'SAN FRANCISCO',
        'CallerCity' => 'SAN FRANCISCO',
        'To' => '+14157669926',
        'FromZip' => '94108',
        'FromCountry' => 'US',
        'ToCity' => '',
        'CallStatus' => 'ringing',
        'CalledCity' => '',
        'CallerState' => 'CA',
        'CalledZip' => '',
        'ToZip' => '',
        'ToCountry' => 'US',
        'CallSid' => 'CA136d09cd59a3c0ec8dbff44da5c03f31',
        'CalledCountry' => 'US',
        'Called' => '+14157669926',
        'ApiVersion' => '2010-04-01',
        'ApplicationSid' => 'AP44efecad51364e80b133bb7c07eb8204'
      }
    end

    def assert_valid!(valid)
      expect(subject.validate(url, params, signature)).to eq(valid)
    end

    context "with a valid signature" do
      let(:signature) { 'oVb2kXoVy8GEfwBDjR8bk/ZZ6eA=' }
      it { assert_valid!(true) }
    end

    context "with an invalid signature" do
      let(:signature) { "foo" }
      it { assert_valid!(false) }
    end
  end
end
