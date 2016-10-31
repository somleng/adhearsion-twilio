require 'spec_helper'

describe Adhearsion::Twilio::Util::NumberNormalizer do
  # Phone Numbers

  # All phone numbers in requests from Twilio are in E.164 format if possible.
  # For example, (415) 555-4345 would come through as '+14155554345'.
  # However, there are occasionally cases where Twilio cannot normalize an
  # incoming caller ID to E.164. In these situations Twilio will report
  # the raw caller ID string.

  describe "#normalize(number)" do
    let(:result) { subject.normalize(number) }

    context "number is:" do
      context "'sip:1000@192.168.1.128'" do
        let(:number) { "sip:1000@192.168.1.128" }
        it { expect(result).to eq("+1000") }
      end

      context "' <85513827719@117.55.252.146:5060>'" do
        let(:number) { " <85513827719@117.55.252.146:5060>" }
        it { expect(result).to eq("+85513827719") }
      end

      context "'<+85510212050@anonymous.invalid>'" do
        let(:number) { "<+85510212050@anonymous.invalid>" }
        it { expect(result).to eq("+85510212050") }
      end

      context "'<85510212050@anonymous.invalid>'" do
        let(:number) { "<85510212050@anonymous.invalid>" }
        it { expect(result).to eq("+85510212050") }
      end

      context "'sofia/gateway/pin_kh_01/85512345678'" do
        let(:number) { "sofia/gateway/pin_kh_01/85512345678" }
        it { expect(result).to eq("+85512345678") }
      end
    end
  end
end
