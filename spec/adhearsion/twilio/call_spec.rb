require 'spec_helper'

describe Adhearsion::Twilio::Call do
  include MockCall

  subject { described_class.new(mock_call) }

  describe "#id" do
    it { expect(subject.id).to eq(mock_call.id) }
  end

  # Phone Numbers

  # All phone numbers in requests from Twilio are in E.164 format if possible.
  # For example, (415) 555-4345 would come through as '+14155554345'.
  # However, there are occasionally cases where Twilio cannot normalize an
  # incoming caller ID to E.164. In these situations Twilio will report
  # the raw caller ID string.

  describe "#to" do
    let(:result) { subject.to }

    before do
      setup_scenario
    end

    def setup_scenario
      allow(mock_call).to receive(:to).and_return(to)
    end

    context "normalization examples" do
      let(:to) { "sofia/gateway/pin_kh_01/85512345678" }
      it { expect(result).to eq("+85512345678") }
    end
  end

  describe "#from" do
    let(:result) { subject.from }

    before do
      setup_scenario
    end

    context "given a call is received from:" do
      def setup_scenario
        allow(mock_call).to receive(:from).and_return(from)
      end

      context "'sip:1000@192.168.1.128'" do
        let(:from) { "sip:1000@192.168.1.128" }
        it { expect(result).to eq("+1000") }
      end

      context "' <85513827719@117.55.252.146:5060>'" do
        let(:from) { " <85513827719@117.55.252.146:5060>" }
        it { expect(result).to eq("+85513827719") }
      end

      context "'<+85510212050@anonymous.invalid>'" do
        let(:from) { "<+85510212050@anonymous.invalid>" }
        it { expect(result).to eq("+85510212050") }
      end

      context "'<85510212050@anonymous.invalid>'" do
        let(:from) { "<85510212050@anonymous.invalid>" }
        it { expect(result).to eq("+85510212050") }
      end

      context "'<anonymous@anonymous.invalid>'" do
        let(:from) { "<anonymous@anonymous.invalid>" }

        context "and the P-Asserted-Identity header is not available" do
          def setup_scenario
            super
            allow(mock_call).to receive(:variables).and_return({})
          end

          it { expect(result).to eq("anonymous") }
        end

        context "and the P-Asserted-Identity header is '+85510212050'" do
          def setup_scenario
            super
            allow(mock_call).to receive(:variables).and_return({"variable_sip_p_asserted_identity" => "+85510212050"})
          end

          it { expect(result).to eq("+85510212050") }
        end # context "and the P-Asserted-Identity header is '+85510212050'"

        context "and the P-Asserted-Identity header is 'foo'" do
          def setup_scenario
            super
            allow(mock_call).to receive(:variables).and_return({:x_variable_sip_p_asserted_identity=>"foo"})
          end

          it { expect(result).to eq("anonymous") }
        end
      end
    end
  end
end
