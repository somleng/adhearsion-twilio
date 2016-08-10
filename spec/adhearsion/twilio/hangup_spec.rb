require 'spec_helper'

describe Adhearsion::Twilio::ControllerMethods, :type => :call_controller do
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

    let(:cassette) { :hangup }

    def assert_call_controller_assertions!
      assert_hungup!
    end

    it { run_and_assert! }
  end
end
