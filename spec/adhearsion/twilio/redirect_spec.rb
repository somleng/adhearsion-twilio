require 'spec_helper'

describe Adhearsion::Twilio::ControllerMethods, :type => :call_controller do
  describe "<Redirect>" do
    # From: http://www.twilio.com/docs/api/twiml/redirect

    # The <Redirect> verb transfers control of a call to the TwiML at a different URL.
    # All verbs after <Redirect> are unreachable and ignored.

    let(:cassette) { :redirect }

    def assert_call_controller_assertions!
    end

    describe "Nouns" do
      # The "noun" of a TwiML verb is the stuff nested within the verb that's not a verb itself;
      # it's the stuff the verb acts upon. These are the nouns for <Redirect>:

      # | Noun       | TwiML Interpretation                                        |
      # | plain text | An absolute or relative URL for a different TwiML document. |

      context "empty" do
        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Redirect/>
        # </Response>

        def assert_call_controller_assertions!
          assert_hungup!
        end

        it { run_and_assert! }
      end # context "empty"

      context "present" do
        # Given the following examples:

        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Redirect>"http://localhost:3000/some_other_endpoint.xml"</Redirect>
        # </Response>

        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Redirect>../relative_endpoint.xml</Redirect>
        # </Response>

        it_should_behave_like "a TwiML 'action' attribute" do
          let(:cassette) { :redirect_with_action }
        end
      end
    end # describe "Nouns"

    describe "Verb Attributes" do
      # From: http://www.twilio.com/docs/api/twiml/redirect

      # The <Redirect> verb supports the following attributes that modify its behavior:

      # | Attribute Name | Allowed Values | Default Value |
      # | method         | GET, POST      | POST          |

      describe "'method'" do
        # From: http://www.twilio.com/docs/api/twiml/redirect

        # The 'method' attribute takes the value 'GET' or 'POST'.
        # This tells Twilio whether to request the <Redirect> URL via HTTP GET or POST.
        # 'POST' is the default.

        # Given the following examples:

        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Redirect>"http://localhost:3000/some_other_endpoint.xml"</Redirect>
        # </Response>

        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Redirect method="GET">"http://localhost:3000/some_other_endpoint.xml"</Redirect>
        # </Response>

        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Redirect method="POST">"http://localhost:3000/some_other_endpoint.xml"</Redirect>
        # </Response>

        it_should_behave_like "a TwiML 'method' attribute" do
          let(:without_method_cassette) { :redirect_with_action }
          let(:with_method_cassette) { :redirect_with_action_and_method }
        end
      end # describe "'method'"
    end # describe "Verb Attributes"
  end # describe "<Redirect>"
end
