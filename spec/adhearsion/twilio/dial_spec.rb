require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include_context "twilio"
        include SharedExamples

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
            allow(dial_status).to receive(:result).and_return(status)
          end

          let(:number_to_dial) { "+415-123-4567" }
          let(:dial_status) { double(Adhearsion::CallController::DialStatus, :result => :answer ) }

          def expect_call_status_update(options = {}, &block)
            super({:to => number_to_dial}.merge(options), &block)
          end

          def assert_dial(options = {})
            asserted_to = options.delete(:to) || number_to_dial

            if asserted_to.is_a?(Array)
              asserted_to_hash = {}
              asserted_to.each do |number|
                asserted_to_hash[number] = {}
              end
              asserted_to = asserted_to_hash
            end

            expect(subject).to receive(:dial) do |to, params|
              expect(to).to eq(asserted_to)
              options.each do |option, value|
                expect(params[option]).to eq(value)
              end
              dial_status
            end
          end

          before do
            allow(subject).to receive(:dial).and_return(dial_status)
            allow(dial_status).to receive(:joins).and_return({})
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

            context "<Number> (Differs from Twilio)" do
              # From: http://www.twilio.com/docs/api/twiml/dial

              # The <Number> noun allows you to <Dial> another number while
              # specifying additional behavior pertaining to that number.
              # Simultaneous dialing is also possible using multiple <Number> nouns.\
              # See the documentation on the <Number> noun for a
              # detailed walkthrough of how to use it.

              # From: http://www.twilio.com/docs/api/twiml/number

              # The <Dial> verb's <Number> noun specifies a phone number to dial.
              # Using the noun's attributes you can specify particular behaviors that
              # Twilio should apply when dialing the number.

              # You can use multiple <Number> nouns within a <Dial> verb
              # to simultaneously call all of them at once.
              # The first call to pick up is connected to the current call
              # and the rest are hung up.

              describe "Noun Attributes" do
                # From: http://www.twilio.com/docs/api/twiml/number

                # Noun Attributes

                # The <Number> noun supports the following attributes that modify its behavior:

                # | Attribute Name | Allowed Values | Default Value |
                # | sendDigits     | any digits     | none          |
                # | method         | GET, POST      | POST          |

                # Phone numbers should be formatted with a '+' and country code
                # e.g., +16175551212 (E.164 format).
                # Twilio will also accept unformatted US numbers
                # e.g., (415) 555-1212 or 415-555-1212.

                describe "none" do
                  # From: http://www.twilio.com/docs/api/twiml/number

                  # In this case we use several <Number> tags to dial three phone numbers
                  # at the same time.
                  # The first of these calls to answer will be connected to the current caller,
                  # while the rest of the connection attempts are canceled.

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial>
                  #     <Number>858-987-6543</Number>
                  #     <Number>415-123-4567</Number>
                  #     <Number>619-765-4321</Number>
                  #   </Dial>
                  # </Response>

                  let(:numbers) { ["858-987-6543", "415-123-4567", "619-765-4321"] }

                  it "should dial simultaneously to the numbers specified" do
                    assert_dial(:to => numbers)
                    expect_call_status_update(:cassette => :dial_number, :numbers => numbers) do
                      subject.run
                    end
                  end
                end # describe "none"

                describe "'callerId' (Not available for Twilio)" do
                  # This option is not available on Twilio

                  # The 'callerId' attribute allows you to tell Adhearsion to dial out
                  # using the callerId for this number

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial callerId="2441">
                  #     <Number callerId="2442">858-987-6543</Number>
                  #     <Number callerId="2443">415-123-4567</Number>
                  #     <Number>619-765-4321</Number>
                  #   </Dial>
                  # </Response>

                  let(:numbers) {
                    {
                      "858-987-6543" => {:from => "2442"},
                      "415-123-4567" => {:from => "2443"},
                      "619-765-4321" => {}
                    }
                  }

                  it "should dial simultaneously to the numbers specified overriding the callerId" do
                    assert_dial(:to => numbers, :from => "2441")
                    expect_call_status_update(:cassette => :dial_number_with_caller_id, :numbers => numbers, :caller_id => "2441") do
                      subject.run
                    end
                  end
                end # describe "'callerId'"

                describe "'sendDigits'" do
                  # From: http://www.twilio.com/docs/api/twiml/number

                  # sendDigits

                  # The 'sendDigits' attribute tells Twilio
                  # to play DTMF tones when the call is answered.
                  # This is useful when dialing a phone number and an extension.
                  # Twilio will dial the number, and when the automated system picks up,
                  # send the DTMF tones to connect to the extension.

                  # In this case, we want to dial the 1928 extension at 415-123-4567.
                  # We use a <Number> noun to describe the phone number
                  # and give it the attribute sendDigits.
                  # We want to wait before sending the extension,
                  # so we add a few leading 'w' characters.
                  # Each 'w' character tells Twilio to wait 0.5 seconds instead
                  # of playing a digit.
                  # This lets you adjust the timing of when the digits begin playing
                  # to suit the phone system you are dialing.

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial>
                  #     <Number sendDigits="wwww1928">
                  #       415-123-4567
                  #     </Number>
                  #   </Dial>
                  # </Response>

                  pending "Not yet implemented"
                end # describe "'sendDigits'"

                describe "'url'" do
                  # From: http://www.twilio.com/docs/api/twiml/number

                  # url

                  # The 'url' attribute allows you to specify a url for a TwiML document that
                  # will run on the called party's end, after she answers,
                  # but before the parties are connected.
                  # You can use this TwiML to privately play or say information to the called party,
                  # or provide a chance to decline the phone call using <Gather> and <Hangup>.
                  # The current caller will continue to hear ringing while the TwiML document
                  # executes on the other end.
                  # TwiML documents executed in this manner
                  # are not allowed to contain the <Dial> verb.

                  pending "Not yet implemented"
                end # describe "'url'"

                describe "'method'" do
                  # From: http://www.twilio.com/docs/api/twiml/number

                  # method

                  # The 'method' attribute allows you to specify which HTTP method Twilio
                  # should use when requesting the URL in the 'url' attribute.
                  # The default is POST.

                  pending "Not yet implemented"
                end # describe "'method'"
              end # describe "Noun Attributes"
            end # context "<Number>"

            context "<Sip>" do
              # From: http://www.twilio.com/docs/api/twiml/sip

              describe "Noun Attributes" do
                # From: http://www.twilio.com/docs/api/twiml/sip

                describe "none" do
                  # From: http://www.twilio.com/docs/api/twiml/sip

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Dial>
                  #     <Sip>sip:jack@example.com</Sip>
                  #   </Dial>
                  # </Response>

                  # not yet supported
                  it "should raise an error that this is not (yet) supported" do
                    expect_call_status_update(
                      :cassette => :dial_sip,
                      :sip_string => "sip:jack@example.com",
                      :assert_hangup => false
                    ) do
                      expect { subject.run }.to raise_error(
                        Adhearsion::Twilio::TwimlError, "Nested noun '<Sip>' not allowed within '<Dial>'"
                      )
                    end
                  end
                end # describe "none"
              end # describe "Noun Attributes"
            end # context "<Sip>"
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

                # Given the following examples:

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial>+415-123-4567</Dial>
                #   <Play>foo.mp3</Play>
                # </Response

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial>+415-123-4567</Dial>
                # </Response

                it_should_behave_like "continuing to process the current TwiML" do
                  let(:cassette) { :dial }
                end
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
                    :cassette => :dial_with_action,
                    :action => redirect_url, :redirect_url => redirect_url}.merge(options), &block
                  )
                end

                # Given the following examples:

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

                it_should_behave_like "a TwiML 'action' attribute" do
                  let(:cassette) { :dial_with_action }
                end

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial action="http://localhost:3000/some_other_endpoint.xml">+415-123-4567</Dial>
                #   <Play>foo.mp3</Play>
                # </Response

                it "should stop continuing with the current TwiML" do
                  assert_next_verb_not_reached
                  expect_call_status_update do
                    subject.run
                  end
                end

                context "the call was joined" do
                  let(:outbound_call) { create_outbound_call }
                  let(:outbound_call_joins_status) {
                    create_joins_status(:result => :no_answer)
                  }

                  let(:dial_status_result) { :answer }
                  let(:joined_outbound_call_sid) { "481f77b9-a95b-4c6a-bbb1-23afcc42c959" }

                  let(:joined_outbound_call) {
                    create_outbound_call(:id => joined_outbound_call_sid)
                  }

                  let(:joined_outbound_call_joins_status) {
                    create_joins_status(:result => :joined, :duration => 23.7)
                  }

                  def create_outbound_call(options = {})
                    double(Adhearsion::OutboundCall, options)
                  end

                  def create_joins_status(options = {})
                    double(Adhearsion::CallController::Dial::JoinStatus, options)
                  end

                  def joins
                    {
                      outbound_call => outbound_call_joins_status,
                      joined_outbound_call => joined_outbound_call_joins_status
                    }
                  end

                  before do
                    stub_dial_status(dial_status_result)
                    allow(dial_status).to receive(:joins).and_return(joins)
                    expect_call_status_update { subject.run }
                  end

                  it "should post DialCallSid and DialCallDuration" do
                    assert_voice_request_params(
                      "DialCallStatus" => "completed",
                      "DialCallSid" => joined_outbound_call_sid,
                      "DialCallDuration" => "23",
                      :request_position => :last
                    )
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
                        assert_voice_request_params("DialCallStatus" => twilio_status, :request_position => :last)
                      end
                    end # context "ahn_status"
                  end # ahn_twilio_dial_statuses loop
                end # context "Adhearsion::CallController::DialStatus#result returns"
              end  # context "specified"
            end # describe "'action'"

            describe "'method'" do
              # From: http://www.twilio.com/docs/api/twiml/dial

              # The 'method' attribute takes the value 'GET' or 'POST'.
              # This tells Twilio whether to request the 'action' URL via HTTP GET or POST.
              # This attribute is modeled after the HTML form 'method' attribute.
              # 'POST' is the default value.

              # Given the following examples:

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Dial action="http://localhost:3000/some_other_endpoint.xml">
              #     +415-123-4567
              #   </Dial>
              # </Response

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Dial action="http://localhost:3000/some_other_endpoint.xml" method="GET">
              #     +415-123-4567
              #   </Dial>
              # </Response

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Dial action="http://localhost:3000/some_other_endpoint.xml" method="POST">
              #     +415-123-4567
              #   </Dial>
              # </Response

              it_should_behave_like "a TwiML 'method' attribute" do
                let(:cassette) { :dial_with_action }
              end
            end

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

            describe "ringback (Not available for Twilio)" do
              # This option is not available on Twilio

              # The 'ringback' attribute allows you to tell Adhearsion to play a ringback
              # tone to leg A when calling leg B

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Dial ringback="http://api.twilio.com/cowbell.mp3">+415-123-4567</Dial>
              # </Response>

              let(:ringback) { "http://api.twilio.com/cowbell.mp3" }

              it "should dial with the specified 'ringback' tone" do
                assert_dial(:ringback => ringback)
                expect_call_status_update(:cassette => :dial_with_ringback, :ringback => ringback) do
                  subject.run
                end
              end
            end # describe "ringback"
          end # describe "Verb Attributes"
        end # describe "<Dial>"
      end # describer "mixed in to a CallController"
    end # describe ControllerMethods
  end # module Twilio
end # module Adhearsion
