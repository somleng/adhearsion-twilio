require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include_context "twilio"

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
          #   <Hangup/>
          # </Response>

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

              def assert_reject!
                assert_next_verb_not_reached
                expect(subject).not_to receive(:answer)
                expect(subject).to receive(:reject).with(asserted_reject_reason)
                expect_call_status_update(
                  {:assert_answered => false}.merge(cassette_options)
                ) { subject.run }
              end

              describe "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/reject

                # If this attribute's value isn't set, the default is "rejected."

                let(:asserted_reject_reason) { :decline }
                let(:cassette_options) { { :cassette => :reject } }

                it "should reject with reason 'decline' then hangup the call" do
                  assert_reject!
                end
              end # describe "'not specified'"

              describe "'busy'" do
                # From: http://www.twilio.com/docs/api/twiml/reject

                # Selecting "busy" will play a busy signal to the caller.

                let(:asserted_reject_reason) { :busy }
                let(:cassette_options) { { :cassette => :reject_with_reason, :reject_reason => "busy" } }

                xit "should play a busy signal"

                it "should reject with reason 'busy' then hangup the call" do
                  assert_reject!
                end
              end # describe "'busy'"

              describe "'rejected'" do
                # From: http://www.twilio.com/docs/api/twiml/reject

                # Selecting "rejected" will play a standard not-in-service response.

                let(:asserted_reject_reason) { :decline }
                let(:cassette_options) { { :cassette => :reject_with_reason, :reject_reason => "rejected" } }

                xit "should play a standard not-in-service response"

                it "should reject with reason 'decline' then hangup the call" do
                  assert_reject!
                end
              end # describe "'rejected'"
            end # describe "'reason'"
          end # describe "Verb Attributes"
        end # describe "<Reject>"
      end # describe "mixed in to a CallController"
    end # describe ControllerMethods
  end # module Twilio
end # module Adhearsion
