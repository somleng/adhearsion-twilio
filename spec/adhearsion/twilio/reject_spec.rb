require 'spec_helper'

describe Adhearsion::Twilio::ControllerMethods, :type => :call_controller do
  describe "<Reject>" do
    # From: http://www.twilio.com/docs/api/twiml/reject

    # The <Reject> verb rejects an incoming call to your Twilio number without billing you.
    # This is very useful for blocking unwanted calls.

    # If the first verb in a TwiML document is <Reject>,
    # Twilio will not pick up the call.
    # The call ends with a status of 'busy' or 'no-answer',
    # depending on the verb's 'reason' attribute.
    # Any verbs after <Reject> are unreachable and ignored.

    # Note that using <Reject> as the first verb in your response is the only way
    # to prevent Twilio from answering a call.
    # Any other response will result in an answered call and your account will be billed.

    # <?xml version="1.0" encoding="UTF-8"?>
    # <Response>
    #   <Reject/>
    # </Response>

    let(:cassette) { :reject }
    let(:asserted_verb) { :reject }
    let(:asserted_verb_args) { [any_args] }

    def assert_call_controller_assertions!
      expect(subject).not_to receive(:answer)
      assert_verb!
    end

    it { run_and_assert! }

    describe "Verb Attributes" do
      # The <Reject> verb supports the following attributes that modify its behavior:

      # | Attribute    | Allowed Values | Default Value              |
      # | reason       | busy, rejected | rejected                   |

      describe "'reason'" do
        # From: http://www.twilio.com/docs/api/twiml/reject

        # The reason attribute takes the values "rejected" and "busy."
        # This tells Twilio what message to play when rejecting a call.
        # Selecting "busy" will play a busy signal to the caller,
        # while selecting "rejected" will play a standard not-in-service response.
        # If this attribute's value isn't set, the default is "rejected."

        let(:asserted_verb_args) { [asserted_reject_reason] }
        let(:cassette) { :reject_with_reason }

        def cassette_options
          super.merge(:reject_reason => reject_reason)
        end

        describe "not specified" do
          # From: http://www.twilio.com/docs/api/twiml/reject

          # If this attribute's value isn't set, the default is "rejected."

          let(:reject_reason) { nil }
          let(:cassette) { :reject }
          let(:asserted_reject_reason) { :decline }

          it { run_and_assert! }
        end # describe "'not specified'"

        describe "'busy'" do
          # From: http://www.twilio.com/docs/api/twiml/reject

          # Selecting "busy" will play a busy signal to the caller.

          let(:reject_reason) { "busy" }
          let(:asserted_reject_reason) { :busy }

          xit "should play a busy signal"

          it { run_and_assert! }
        end # describe "'busy'"

        describe "'rejected'" do
          # From: http://www.twilio.com/docs/api/twiml/reject

          # Selecting "rejected" will play a standard not-in-service response.

          let(:reject_reason) {  "rejected" }
          let(:asserted_reject_reason) { :decline }

          xit "should play a standard not-in-service response"

          it { run_and_assert! }
        end # describe "'rejected'"
      end # describe "'reason'"
    end # describe "Verb Attributes"
  end # describe "<Reject>"
end
