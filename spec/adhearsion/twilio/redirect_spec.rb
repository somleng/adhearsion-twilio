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

              it "should raise a TWimlError" do
                expect {
                  expect_call_status_update(:cassette => :redirect) { subject.run }
                 }.to raise_error(Adhearsion::Twilio::TwimlError, "invalid redirect url")
              end
            end # context "empty"

            context "absolute url" do
              # From: http://www.twilio.com/docs/api/twiml/redirect

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Redirect>"http://localhost:3000/some_other_endpoint.xml"</Redirect>
              # </Response>

              it "should redirect to the absolute url" do
                expect_call_status_update(:cassette => :redirect_with_absolute_url, :redirect_url => redirect_url) do
                  subject.run
                end
                last_request(:url).should == redirect_url
              end
            end # context "absolute url"

            context "relative url" do
              let(:relative_url) { "../relative_endpoint.xml" }

              let(:redirect_url) do
                URI.join(default_config[:voice_request_url], relative_url).to_s
              end

              # From: http://www.twilio.com/docs/api/twiml/redirect

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Redirect>../relative_endpoint.xml</Redirect>
              # </Response>

              it "should redirect to the relative url" do
                expect_call_status_update(:cassette => :redirect_with_relative_url, :relative_url => relative_url, :redirect_url => redirect_url) do
                  subject.run
                end
                last_request(:url).should == redirect_url
              end
            end # context "relative url"
          end # describe "Nouns"

          describe "Verb Attributes" do
            # From: http://www.twilio.com/docs/api/twiml/redirect

            # The <Redirect> verb supports the following attributes that modify its behavior:

            # | Attribute Name | Allowed Values | Default Value |
            # | method         | GET, POST      | POST          |

            def expect_call_status_update(options = {}, &block)
              super({:redirect_url => redirect_url}.merge(options), &block)
            end

            describe "'method'" do
              # From: http://www.twilio.com/docs/api/twiml/redirect

              # The 'method' attribute takes the value 'GET' or 'POST'.
              # This tells Twilio whether to request the <Redirect> URL via HTTP GET or POST.
              # 'POST' is the default.

              context "not supplied" do
                # From: http://www.twilio.com/docs/api/twiml/redirect

                # "'POST' is the default."

                before do
                  ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "get"
                end

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Redirect>"http://localhost:3000/some_other_endpoint.xml"</Redirect>
                # </Response>

                it "should redirect using a 'POST'" do
                  expect_call_status_update(:cassette => :redirect_with_absolute_url) do
                    subject.run
                  end
                  last_request(:method).should == :post
                end
              end # context "not supplied"

              context "supplied" do
                context "'GET'" do
                  # From: http://www.twilio.com/docs/api/twiml/redirect

                  # "This tells Twilio whether to request the <Redirect> URL via HTTP GET."

                  before do
                    ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "post"
                  end

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Redirect method="GET">"http://localhost:3000/some_other_endpoint.xml"</Redirect>
                  # </Response>

                  it "should redirect using a 'GET' request" do
                    expect_call_status_update(:cassette => :redirect_with_method, :redirect_method => "get") do
                      subject.run
                    end
                    last_request(:method).should == :get
                  end
                end # context "'GET'"

                context "'POST'" do
                  # From: http://www.twilio.com/docs/api/twiml/redirect

                  # "This tells Twilio whether to request the <Redirect> URL via HTTP POST."

                  before do
                    ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "get"
                  end

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Redirect method="POST">"http://localhost:3000/some_other_endpoint.xml"</Redirect>
                  # </Response>

                  it "should redirect using a 'POST' request" do
                    expect_call_status_update(:cassette => :redirect_with_method, :redirect_method => "post") do
                      subject.run
                    end
                    last_request(:method).should == :post
                  end
                end # context "'POST'"
              end # context "supplied"
            end # describe "'method'"
          end # describe "Verb Attributes"
        end # describe "<Redirect>"
      end # describe "mixed in to a CallController"
    end # describe "ControllerMethods"
  end # module Twilio
end # module Adhearsion
