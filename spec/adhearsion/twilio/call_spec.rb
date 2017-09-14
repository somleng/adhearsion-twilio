require 'spec_helper'

describe Adhearsion::Twilio::Call do
  include MockCall

  subject { described_class.new(mock_call) }

  describe "#id" do
    it { expect(subject.id).to eq(mock_call.id) }
  end

  describe "#to" do
    let(:result) { subject.to }
    let(:to) { "+85512345678" }

    before do
      setup_scenario
    end

    def setup_scenario
      allow(mock_call).to receive(:to).and_return(to)
    end

    it { expect(result).to eq("+85512345678") }
  end

  describe "#duration" do
    let(:result) { subject.duration }

    before do
      setup_scenario
    end

    def setup_scenario
      allow(mock_call).to receive(:duration).and_return("26.4")
    end

    it { expect(result).to eq(26) }
  end

  describe "#variables" do
    it { expect(subject.variables).to eq(mock_call.variables) }
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
