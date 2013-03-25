require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include_context "twilio"

        describe "<Redirect>" do
          # From: http://www.twilio.com/docs/api/twiml/redirect

          # The <Redirect> verb transfers control of a call to the TwiML at a different URL.
          # All verbs after <Redirect> are unreachable and ignored.

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

              it "should raise a TwimlError" do
                expect {
                  expect_call_status_update(:cassette => :redirect) { subject.run }
                 }.to raise_error(Adhearsion::Twilio::TwimlError, "invalid redirect url")
              end
            end # context "empty"

            # Given the follwoing examples:

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Redirect>"http://localhost:3000/some_other_endpoint.xml"</Redirect>
            # </Response>

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Redirect>../relative_endpoint.xml</Redirect>
            # </Response>

            it_should_behave_like "a TwiML 'action' attribute", :redirect_with_action
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

              it_should_behave_like "a TwiML 'method' attribute", :redirect_with_action
            end # describe "'method'"
          end # describe "Verb Attributes"
        end # describe "<Redirect>"
      end # describe "mixed in to a CallController"
    end # describe "ControllerMethods"
  end # module Twilio
end # module Adhearsion
