require 'spec_helper'
require "adhearsion/twilio/util/sip_header"

describe Adhearsion::Twilio::Util::SipHeader do
  describe "#construct_header_name(name)" do
    let(:name) { "my_variable" }
    let(:result) { subject.construct_header_name(name) }

    def assert_construct_header_name!
      expect(result).to eq("X-Adhearsion-Twilio-my_variable")
    end

    it { assert_construct_header_name! }
  end
end
