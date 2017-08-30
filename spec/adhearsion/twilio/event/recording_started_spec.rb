require 'spec_helper'

describe Adhearsion::Twilio::Event::RecordingStarted do
  let(:call_id) { "call-id" }
  let(:params) { {"foo" => "bar"} }
  subject { described_class.new(call_id, params) }

  describe "#call_id" do
    it { expect(subject.call_id).to eq(call_id) }
  end

  describe "#params" do
    it { expect(subject.params).to eq(params) }
  end
end
