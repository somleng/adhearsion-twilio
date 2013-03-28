require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include_context "twilio"

        describe "<Hangup>" do
          # From: http://www.twilio.com/docs/api/twiml/hangup

          # The <Hangup> verb ends a call.
          # If used as the first verb in a TwiML response it
          # does not prevent Twilio from answering the call and billing your account.
          # The only way to not answer a call and prevent billing is to use the <Reject> verb.

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Hangup/>
          # </Response>

          it "should hang up the call" do
            # hangup already asserted in following assertion
            expect_call_status_update(:cassette => :hangup) { subject.run }
          end
        end
      end
    end
  end
end
