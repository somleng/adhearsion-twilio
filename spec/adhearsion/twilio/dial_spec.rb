require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include_context "twilio"

        describe "<Dial>" do
          # From: http://www.twilio.com/docs/api/twiml/dial

          # The <Dial> verb connects the current caller to another phone.
          # If the called party picks up, the two parties are connected and can
          # communicate until one hangs up. If the called party does not pick up,
          # if a busy signal is received, or if the number doesn't exist,
          # the dial verb will finish.

          # When the dialed call ends, Twilio makes a GET or POST request
          # to the 'action' URL if provided.
          # Call flow will continue using the TwiML received in response to that request.

          def stub_dial_status(status)
            dial_status.stub(:result).and_return(status)
          end

          let(:number_to_dial) { "+415-123-4567" }
          let(:dial_status) { mock(Adhearsion::CallController::DialStatus, :result => :answer ) }

          def expect_call_status_update(options = {}, &block)
            super({:to => number_to_dial}.merge(options), &block)
          end

          def assert_dial(options = {})
            subject.should_receive(:dial) do |number, params|
              number.should == number_to_dial
              options.each do |option, value|
                params[option].should == value
              end
              dial_status
            end
          end

          before do
            subject.stub(:dial).and_return(dial_status)
          end

          describe "Nouns" do
            # From: http://www.twilio.com/docs/api/twiml/dial

            # "The "noun" of a TwiML verb is the stuff nested within the verb that's not a verb itself;
            # it's the stuff the verb acts upon. These are the nouns for <Dial>:"

            # | Noun         | Description                                                       |
            # | plain text   | A string representing a valid phone number to call.               |
            # | <Number>     | A nested XML element that describes                               |
            # |              | a phone number with more complex attributes.                      |
            # | <Client>     | A nested XML element that describes a Twilio Client connection.   |
            # | <Sip>        | A nested XML element that describes a SIP connection.             |
            # | <Conference> | A nested XML element that describes a conference                  |
            # |              | allowing two or more parties to talk.                             |
            # | <Queue>      | A nested XML element identifying a queue                          |
            # |              | that this call should be connected to.                            |

            context "plain text" do

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Dial>+415-123-4567</Dial>
              # </Response

              it "should dial to the specified number" do
                assert_dial
                expect_call_status_update(:cassette => :dial, :to => number_to_dial) do
                  subject.run
                end
              end
            end # context "plain text"
          end # describe "Nouns"

          describe "Verb Attributes" do
            # The <Dial> verb supports the following attributes that modify its behavior:

            # | Attribute    | Allowed Values                             | Default Value              |
            # | action       | relative or absolute URL                   | no default action for Dial |
            # | method       | GET, POST                                  | POST                       |
            # | timeout      | positive integer                           | 30 seconds                 |
            # | hangupOnStar | true, false                                | false                      |
            # | timeLimit    | positive integer (seconds)                 | 14400 seconds (4 hours)    |
            # | callerId     | a valid phone number, or client identifier | Caller's callerId          |
            # |              | if you are dialing a <Client>.             |                            |
            # | record       | true, false                                | false                      |

            describe "'action'" do
              # From: http://www.twilio.com/docs/api/twiml/dial

              # The 'action' attribute takes a URL as an argument.
              # When the dialed call ends, Twilio will make a GET or POST request to
              # this URL including the parameters below.

              # If you provide an 'action' URL, Twilio will continue the current call after
              # the dialed party has hung up, using the TwiML received
              # in your response to the 'action' URL request.
              # Any TwiML verbs occurring after a which specifies
              # an 'action' attribute are unreachable.

              # If no 'action' is provided, <Dial> will finish and Twilio will move on
              # to the next TwiML verb in the document. If there is no next verb,
              # Twilio will end the phone call.
              # Note that this is different from the behavior of <Record> and <Gather>.
              # <Dial> does not make a request to the current document's URL by default
              # if no 'action' URL is provided.
              # Instead the call flow falls through to the next TwiML verb.

              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/dial

                # If no 'action' is provided, <Dial> will finish and Twilio will move on
                # to the next TwiML verb in the document. If there is no next verb,
                # Twilio will end the phone call.
                # Note that this is different from the behavior of <Record> and <Gather>.
                # <Dial> does not make a request to the current document's URL by default
                # if no 'action' URL is provided.
                # Instead the call flow falls through to the next TwiML verb.

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial>+415-123-4567</Dial>
                #   <Hangup/>
                # </Response

                it "should continue processing the twiml after the dial" do
                  subject.should_receive(:hangup)
                  expect_call_status_update(:cassette => :dial_hangup, :to => number_to_dial) do
                    subject.run
                  end
                end

                context "with no next verb" do
                  # From: http://www.twilio.com/docs/api/twiml/dial

                  # "If there is no next verb, Twilio will end the phone call."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial>+415-123-4567</Dial>
                  # </Response

                  it "should hangup after the dial" do
                    subject.should_receive(:hangup)
                    expect_call_status_update(:cassette => :dial, :to => number_to_dial) do
                      subject.run
                    end
                  end
                end # context "with no next verb"
              end # context "not specified"

              context "specified" do
                # From: http://www.twilio.com/docs/api/twiml/dial

                # The 'action' attribute takes a URL as an argument.
                # When the dialed call ends, Twilio will make a GET or POST
                # request to this URL including the parameters below.

                # If you provide an 'action' URL, Twilio will continue the current call
                # after the dialed party has hung up, using the TwiML
                # received in your response to the 'action' URL request.
                # Any TwiML verbs occurring after a which specifies an 'action' attribute are unreachable.

                # Request Parameters

                # "Twilio will pass the following parameters in addition to the standard
                # TwiML Voice request parameters with its request to the 'action' URL:"

                # | Parameter        | Description                                              |
                # | DialCallStatus   | The outcome of the <Dial> attempt.                       |
                # |                  | See the DialCallStatus section below for details.        |
                # | DialCallSid      | The call sid of the new call leg.                        |
                # |                  | This parameter is not sent after dialing a conference.   |
                # | DialCallDuration | The duration in seconds of the dialed call.              |
                # |                  | This parameter is not sent after dialing a conference.   |
                # | RecordingUrl     | The URL of the recorded audio.                           |
                # |                  | This parameter is only sent if record="true" is set      |
                # |                  | on the <Dial> verb, and does not include recordings      |
                # |                  | from the <Record> verb or Record=True on REST API calls. |

                # DialCallStatus Values

                # | Value     | Description                                                               |
                # | completed | The called party answered the call and was connected to the caller.       |
                # | busy      | Twilio received a busy signal when trying to connect to the called party. |
                # | no-answer | The called party did not pick up before the timeout period passed.        |
                # | failed    | Twilio was unable to route to the given phone number.                     |
                # |           | This is frequently caused by dialing                                      |
                # |           | a properly formatted but non-existent phone number.                       |
                # | canceled  | The call was canceled via the REST API before it was answered.            |

                def expect_call_status_update(options = {}, &block)
                  super({
                    :cassette => :dial_with_action_then_hangup,
                    :action => redirect_url, :redirect_url => redirect_url}.merge(options), &block
                  )
                end

                it_should_behave_like "a TwiML 'action' attribute" do

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial action="http://localhost:3000/some_other_endpoint.xml">+415-123-4567</Dial>
                  #   <Play>foo.mp3</Play>
                  # </Response

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial action="../relative_endpoint.xml">+415-123-4567</Dial>
                  #   <Play>foo.mp3</Play>
                  # </Response
                  let(:cassette_options) { {} }
                end

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial action="http://localhost:3000/some_other_endpoint.xml">+415-123-4567</Dial>
                #   <Play>foo.mp3</Play>
                # </Response

                it "should stop continuing with the current TwiML" do
                  subject.should_not_receive(:play_audio)
                  subject.should_receive(:hangup)
                  expect_call_status_update do
                    subject.run
                  end
                end

                context "Adhearsion::CallController::DialStatus#result returns" do
                  # Adhearsion -> Twilio dial statuses:
                  ahn_twilio_dial_statuses = {
                    :no_answer => "no-answer",
                    :answer => "completed",
                    :timeout => "no-answer",
                    :error => "failed"
                  }

                  ahn_twilio_dial_statuses.each do |ahn_status, twilio_status|
                    context ":#{ahn_status}" do
                      before do
                        stub_dial_status(ahn_status)
                      end

                      # <?xml version="1.0" encoding="UTF-8"?>
                      # <Response>
                      #   <Dial action="http://localhost:3000/some_other_endpoint.xml">+415-123-4567</Dial>
                      #   <Play>foo.mp3</Play>
                      # </Response

                      it "should post a DialCallStatus of '#{twilio_status}'" do
                        expect_call_status_update do
                          subject.run
                        end
                        assert_voice_request_params("DialCallStatus" => twilio_status)
                      end
                    end # context "ahn_status"
                  end # context "Adhearsion::CallController::DialStatus#result returns"
                end # context "specified"
              end # describe "'action'"

              describe "'method'" do
                # From: http://www.twilio.com/docs/api/twiml/dial

                # The 'method' attribute takes the value 'GET' or 'POST'.
                # This tells Twilio whether to request the 'action' URL via HTTP GET or POST.
                # This attribute is modeled after the HTML form 'method' attribute.
                # 'POST' is the default value.

                def expect_call_status_update(options = {}, &block)
                  super({
                    :cassette => :dial_with_method,
                    :action => redirect_url, :redirect_url => redirect_url}.merge(options), &block
                  )
                end

                context "not specified" do
                  # From: http://www.twilio.com/docs/api/twiml/dial

                  # "'POST' is the default value."

                  before do
                    ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "get"
                  end

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial action="http://localhost:3000/some_other_endpoint.xml">
                  #     +415-123-4567
                  #   </Dial>
                  # </Response

                  it "should send a 'POST' request" do
                    expect_call_status_update(:cassette => :dial_with_action_then_hangup) do
                      subject.run
                    end
                    last_request(:method).should == :post
                  end
                end # context "not specified"

                context "specified" do
                  context "'GET'" do
                    # From: http://www.twilio.com/docs/api/twiml/dial

                    # "This tells Twilio whether to request the 'action' URL via HTTP GET"

                    before do
                      ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "post"
                    end

                    # <?xml version="1.0" encoding="UTF-8"?>
                    # <Response>
                    #   <Dial action="http://localhost:3000/some_other_endpoint.xml" method="GET">
                    #     +415-123-4567
                    #   </Dial>
                    # </Response

                    it "should send a 'GET' request to the 'action' param" do
                      expect_call_status_update(:action_method => "get") do
                        subject.run
                      end
                      last_request(:method).should == :get
                    end
                  end # context "'GET'"

                  context "'POST'" do
                    # From: http://www.twilio.com/docs/api/twiml/dial

                    # "This tells Twilio whether to request the 'action' URL via HTTP POST"

                    before do
                      ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "get"
                    end

                    # <?xml version="1.0" encoding="UTF-8"?>
                    # <Response>
                    #   <Dial action="http://localhost:3000/some_other_endpoint.xml" method="POST">
                    #     +415-123-4567
                    #   </Dial>
                    # </Response

                    it "should send a 'POST' request to the 'action' param" do
                      expect_call_status_update(:action_method => "post") do
                        subject.run
                      end
                      last_request(:method).should == :post
                    end
                  end
                end # context "POST'"
              end # context "specified"
            end # describe "'method'"

            describe "'callerId'" do
              # From: http://www.twilio.com/docs/api/twiml/dial

              # The 'callerId' attribute lets you specify the caller ID that will appear
              # to the called party when Twilio calls. By default,
              # when you put a <Dial> in your TwiML response to Twilio's inbound call request,
              # the caller ID that the dialed party sees is the inbound caller's caller ID.

              # For example, an inbound caller to your Twilio number has the caller ID 1-415-123-4567.
              # You tell Twilio to execute a <Dial> verb to 1-858-987-6543 to handle the inbound call.
              # The called party (1-858-987-6543) will see 1-415-123-4567 as the caller ID
              # on the incoming call.

              # If you are dialing to a <Client>, you can set a client identifier
              # as the callerId attribute. For instance, if you've set up a client
              # for incoming calls and you are dialing to it, you could set the callerId
              # attribute to client:tommy.

              # If you are dialing a phone number from a Twilio Client connection,
              # you must specify a valid phone number as the callerId or the call will fail.

              # You are allowed to change the phone number that the called party
              # sees to one of the following:

              # - either the 'To' or 'From' number provided in Twilio's TwiML request to your app
              # - any incoming phone number you have purchased from Twilio
              # - any phone number you have verified with Twilio

              # | Attribute | Allowed Values                             | Default Value     |
              # | callerId  | a valid phone number, or client identifier | Caller's callerId |
              # |           | if you are dialing a <Client>.             |                   |

              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/dial

                # "By default, when you put a <Dial> in your TwiML response to Twilio's
                # inbound call request, the caller ID that the dialed party sees
                # is the inbound caller's caller ID."

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial>+415-123-4567</Dial>
                # </Response

                it "should not dial with any callerId" do
                  assert_dial(:from => nil)
                  expect_call_status_update(:cassette => :dial) do
                    subject.run
                  end
                end
              end # context "not specified"

              context "specified" do
                # From: http://www.twilio.com/docs/api/twiml/dial

                # You are allowed to change the phone number that the called party
                # sees to one of the following:

                # - either the 'To' or 'From' number provided in Twilio's TwiML request to your app
                # - any incoming phone number you have purchased from Twilio
                # - any phone number you have verified with Twilio

                context "'2442'" do
                  let(:caller_id) { "2442" }

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial callerId="2442">+415-123-4567</Dial>
                  # </Response

                  it "should dial from the specified 'callerId'" do
                    assert_dial(:from => caller_id)
                    expect_call_status_update(:cassette => :dial_with_caller_id, :caller_id => caller_id) do
                      subject.run
                    end
                  end
                end # context "'2442'"
              end # context "specified"
            end # describe "'callerId'"

            describe "'timeout'" do
              # From: http://www.twilio.com/docs/api/twiml/dial

              # The 'timeout' attribute sets the limit in seconds that <Dial>
              # waits for the called party to answer the call.
              # Basically, how long should Twilio let the call ring before giving up and
              # reporting 'no-answer' as the 'DialCallStatus'.

              # | Attribute | Allowed Values   | Default Value |
              # | timeout   | positive integer | 30 seconds    |

              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/dial

                # | Attribute | Allowed Values   | Default Value |
                # | timeout   | positive integer | 30 seconds    |

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial>+415-123-4567</Dial>
                # </Response

                it "should dial with a timeout of 30.seconds" do
                  assert_dial(:for => 30.seconds)
                  expect_call_status_update(:cassette => :dial) do
                    subject.run
                  end
                end
              end # context "not specified"

              context "specified" do
                context "'10'" do

                  let(:timeout) { "10" }

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial timeout="10">+415-123-4567</Dial>
                  # </Response

                  it "should dial with the specified 'timeout'" do
                    assert_dial(:for => timeout.to_i.seconds)
                    expect_call_status_update(:cassette => :dial_with_timeout, :timeout => timeout) do
                      subject.run
                    end
                  end
                end # context "'10'"
              end # context "specified"
            end # describe "'timeout'"
          end # describe "Verb Actions"
        end # describe "<Dial>"
      end # describer "mixed in to a CallController"
    end # describe ControllerMethods
  end # module Twilio
end # module Adhearsion
