require 'spec_helper'

describe Adhearsion::Twilio::Util::SipHeader do
  describe "#construct_header_name(name)" do
    let(:name) { "my_variable" }
    let(:result) { subject.construct_header_name(name) }

    def assert_construct_header_name!
      expect(result).to eq("X-Adhearsion-Twilio-my_variable")
    end

    it { assert_construct_header_name! }
  end

  describe "#construct_call_variable_name(name)" do
    let(:name) { "my-variable" }
    let(:result) { subject.construct_call_variable_name(name) }

    def assert_construct_call_variable_name!
      expect(result).to eq("x_adhearsion_twilio_my_variable")
    end

    it { assert_construct_call_variable_name! }
  end
end
