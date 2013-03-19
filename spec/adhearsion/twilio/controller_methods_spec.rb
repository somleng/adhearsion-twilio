require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include WebMockHelpers

        class TestController < Adhearsion::CallController
          include Twilio::ControllerMethods

          def run
            redirect
          end
        end

        let(:call_params) do
          {
            :to => "85512456869",
            :from => "1000",
            :id => "5150691c-3db4-11e2-99cd-1f3f1cd7995d"
          }
        end

        let(:call) do
          mock(
            "Call",
            :from => "Extension 1000 <#{call_params[:from]}@192.168.42.234>",
            :to => "#{call_params[:to]}@192.168.42.234",
            :id => call_params[:id]
          )
        end

        let(:redirect_url) do
          uri_with_authentication("http://localhost:3000/some_other_endpoint.xml").to_s
        end

        let(:alternate_redirect_method) { :get }

        before do
          subject.stub(:hangup)
          call.stub(:alive?)
        end

        subject { TestController.new(call) }

        def default_config
          {
            :voice_request_url => ENV["AHN_TWILIO_VOICE_REQUEST_URL"] || "http://localhost:3000/",
            :voice_request_method => ENV["AHN_TWILIO_VOICE_REQUEST_METHOD"] || :post,
            :voice_request_user => ENV["AHN_TWILIO_VOICE_REQUEST_USER"] || "user",
            :voice_request_password => ENV["AHN_TWILIO_VOICE_REQUEST_PASSWORD"] || "secret"
          }
        end

        def generate_erb(options = {})
          uri = uri_with_authentication(options.delete(:url) || default_config[:voice_request_url])
          {
            :user => uri.user,
            :password => uri.password,
            :url => uri.to_s,
            :method => default_config[:voice_request_method]
          }.merge(options)
        end

        def uri_with_authentication(url)
          uri = URI.parse(url)
          uri.user ||= default_config[:voice_request_user]
          uri.password ||= default_config[:voice_request_password]
          uri
        end

        def expect_call_status_update(options = {}, &block)
          cassette = options.delete(:cassette) || :hangup
          VCR.use_cassette(cassette, :erb => generate_erb(options)) do
            yield
          end
        end

        def assert_voice_request_params(options = {})
          options["From"] ||= "+#{call_params[:from]}"
          options["To"] ||= "+#{call_params[:to]}"
          options["CallSid"] ||= call_params[:id]
          options["CallStatus"] ||= "in-progress"

          last_request(:body).each do |param, value|
            value.should == options[param]
          end
        end

        describe "posting call status updates" do
          it "should post the correct parameters to the call status voice request url" do
            expect_call_status_update { subject.run }
            assert_voice_request_params
          end
        end

        describe "<Hangup>" do
          # From: http://www.twilio.com/docs/api/twiml/hangup

          # "The <Hangup> verb ends a call.
          # If used as the first verb in a TwiML response it
          # does not prevent Twilio from answering the call and billing your account.
          # The only way to not answer a call and prevent billing is to use the <Reject> verb."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Hangup/>
          # </Response>

          it "should hang up the call" do
            subject.should_receive(:hangup)
            expect_call_status_update { subject.run }
          end
        end

        describe "<Redirect>" do
          # From: http://www.twilio.com/docs/api/twiml/redirect

          # "The <Redirect> verb transfers control of a call to the TwiML at a different URL.
          # All verbs after <Redirect> are unreachable and ignored."

          # Verb Attributes

          # "The <Redirect> verb supports the following attributes that modify its behavior:

          # | Attribute Name | Allowed Values | Default Value |
          # | method         | GET, POST      | POST          |

          # "The 'method' attribute takes the value 'GET' or 'POST'.
          # This tells Twilio whether to request the <Redirect> URL via HTTP GET or POST.
          # 'POST' is the default."

          # Nouns

          # The "noun" of a TwiML verb is the stuff nested within the verb that's not a verb itself;
          # it's the stuff the verb acts upon. These are the nouns for <Redirect>:

          # | Noun       | TwiML Interpretation                                        |
          # | plain text | An absolute or relative URL for a different TwiML document. |

          describe "Nouns" do
            context "empty (Not implemented in Twilio)" do
              # Note: this feature is not implemented in twilio

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Redirect/>
              # </Response>

              it "should redirect to the default voice request url" do
                expect_call_status_update(:cassette => :redirect_no_url) { subject.run }
                last_request(:url).should == uri_with_authentication(default_config[:voice_request_url]).to_s
                last_request(:method).downcase.should == default_config[:voice_request_method]
              end
            end

            context "absolute url (differs from Twilio)" do
              # From: http://www.twilio.com/docs/api/twiml/redirect

              # "'POST' is the default."

              # Note: The behaviour differs slightly here from the behaviour or Twilio.
              # If not method is given, it will default to
              # AHN_TWILIO_VOICE_REQUEST_METHOD or config.voice_request_method

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Redirect>"http://localhost:3000/some_other_endpoint.xml"</Redirect>
              # </Response>

              it "should redirect to the absolute url using the http method specified in AHN_TWILIO_VOICE_REQUEST_METHOD or config.voice_request_method (defaults to 'POST')" do
                expect_call_status_update(:cassette => :redirect_with_url, :redirect_url => redirect_url) do
                  subject.run
                end
                last_request(:url).should == redirect_url
                last_request(:method).downcase.should == default_config[:voice_request_method]
              end

              describe "Verb Attributes" do
                describe "'method'" do
                  context "'GET'" do
                    # From: http://www.twilio.com/docs/api/twiml/redirect

                    # "This tells Twilio whether to request the <Redirect> URL via HTTP GET or POST."

                    # <?xml version="1.0" encoding="UTF-8"?>
                    # <Response>
                    #   <Redirect method="GET">"http://localhost:3000/some_other_endpoint.xml"</Redirect>
                    # </Response>

                    it "should redirect to the absolute url using a 'GET' request" do
                      expect_call_status_update(:cassette => :redirect_with_get_url, :redirect_url => redirect_url, :redirect_method => alternate_redirect_method) do
                        subject.run
                      end
                      last_request(:method).downcase.should == alternate_redirect_method
                    end
                  end
                end
              end
            end

            context "relative url" do
              let(:relative_url) { "../relative_endpoint.xml" }
              let(:redirect_url) do
                uri_with_authentication(URI.join(default_config[:voice_request_url], relative_url).to_s).to_s
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
            end
          end
        end

        describe "<Play>" do
          # From: http://www.twilio.com/docs/api/twiml/play

          # "The <Play> verb plays an audio file back to the caller.
          # Twilio retrieves the file from a URL that you provide."

          # Verb Attributes

          # The <Play> verb supports the following attributes that modify its behavior:
          # | Attribute Name | Allowed Values | Default Value |
          # | loop           | integer >= 0   | 1             |

          # "The 'loop' attribute specifies how many times the audio file is played.
          # The default behavior is to play the audio once.
          # Specifying '0' will cause the the <Play> verb to loop until the call is hung up."

          let(:file_url) { "http://api.twilio.com/cowbell.mp3" }
          let(:infinity) { 20 }

          def expect_call_status_update(options = {}, &block)
            super({:file_url => file_url}.merge(options), &block)
          end

          def stub_infinite_loop
            subject.stub(:loop).and_return(infinity.times)
          end

          def assert_playback(options = {})
            options[:loop] ||= 1
            subject.should_receive(:play_audio).with(file_url, {:renderer => :native}).exactly(options[:loop]).times
          end

          before do
            subject.stub(:play_audio)
          end

          describe "Nouns" do
            # From: http://www.twilio.com/docs/api/twiml/play

            # The "noun" of a TwiML verb is the stuff nested within the verb
            # that's not a verb itself; it's the stuff the verb acts upon.

            # These are the nouns for <Play>:

            # | Noun        | Description                                                                |
            # | plain text  | The URL of an audio file that Twilio will retrieve and play to the caller. |

            # Twilio supports the following audio MIME types for audio files retrieved by the <Play> verb:

            # | MIME type    | Description                    |
            # | audio/mpeg   | mpeg layer 3 audio             |
            # | audio/wav    | wav format audio               |
            # | audio/wave   | wav format audio               |
            # | audio/x-wav  | wav format audio               |
            # | audio/aiff   | audio interchange file format  |
            # | audio/x-aifc | audio interchange file format  |
            # | audio/x-aiff | audio interchange file format  |
            # | audio/x-gsm  | GSM audio format               |
            # | audio/gsm    | GSM audio format               |
            # | audio/ulaw   | μ-law audio format             |

            context "plain text" do
              # <?xml version="1.0" encoding="UTF-8" ?>
              # <Response>
              #   <Play>http://api.twilio.com/cowbell.mp3</Play>
              # </Response>

              it "should play the audio at the specified url" do
                assert_playback
                expect_call_status_update(:cassette => :play) do
                  subject.run
                end
              end
            end
          end

          describe "Verb Attributes" do
            describe "'loop'" do
              # From: http://www.twilio.com/docs/api/twiml/play

              # | Attribute Name | Allowed Values | Default Value |
              # | loop           | integer >= 0   | 1             |

              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/dial

                # "The default behavior is to play the audio once."

                # <?xml version="1.0" encoding="UTF-8" ?>
                # <Response>
                #   <Play>http://api.twilio.com/cowbell.mp3</Play>
                # </Response>

                it "should play the audio once" do
                  assert_playback(:loop => 1)
                  expect_call_status_update(:cassette => :play) do
                    subject.run
                  end
                end
              end

              context "specified" do
                context "'0'" do
                  # From: http://www.twilio.com/docs/api/twiml/play

                  # "Specifying '0' will cause the the <Play> verb to loop until the call is hung up."

                  # <?xml version="1.0" encoding="UTF-8" ?>
                  # <Response>
                  #   <Play loop="0">http://api.twilio.com/cowbell.mp3</Play>
                  # </Response>

                  before do
                    stub_infinite_loop
                  end

                  it "should keep playing the audio until the call is hung up" do
                    assert_playback(:loop => infinity)
                    expect_call_status_update(:cassette => :play_with_loop, :loop => "0") do
                      subject.run
                    end
                  end
                end

                context "'5'" do
                  # From: http://www.twilio.com/docs/api/twiml/play

                  # "The 'loop' attribute specifies how many times the audio file is played."

                  # <?xml version="1.0" encoding="UTF-8" ?>
                  # <Response>
                  #   <Play loop="5">http://api.twilio.com/cowbell.mp3</Play>
                  # </Response>

                  it "should play the audio file 5 times" do
                    assert_playback(:loop => 5)
                    expect_call_status_update(:cassette => :play_with_loop, :loop => "5") do
                      subject.run
                    end
                  end
                end
              end
            end
          end
        end

        describe "<Dial>" do
          # From: http://www.twilio.com/docs/api/twiml/dial

          # "The <Dial> verb connects the current caller to another phone.
          # If the called party picks up, the two parties are connected and can
          # communicate until one hangs up. If the called party does not pick up,
          # if a busy signal is received, or if the number doesn't exist,
          # the dial verb will finish."

          # "When the dialed call ends, Twilio makes a GET or POST request
          # to the 'action' URL if provided.
          # Call flow will continue using the TwiML received in response to that request."

          # Verb Attributes

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

            # Nouns

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
              it "should dial to the specified number" do
                assert_dial
                expect_call_status_update(:cassette => :dial_no_action, :to => number_to_dial) do
                  subject.run
                end
              end
            end
          end

          describe "Verb Attributes" do
            describe "'action'" do
              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/dial

                # "If no 'action' is provided, <Dial> will finish and Twilio will move on
                # to the next TwiML verb in the document. If there is no next verb,
                # Twilio will end the phone call.
                # Note that this is different from the behavior of <Record> and <Gather>.
                # <Dial> does not make a request to the current document's URL by default
                # if no 'action' URL is provided.
                # Instead the call flow falls through to the next TwiML verb."

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial>+415-123-4567</Dial>
                #   <Hangup/>
                # </Response

                it "should continue processing the twiml after the dial" do
                  subject.should_receive(:hangup)
                  expect_call_status_update(:cassette => :dial_hangup_no_action, :to => number_to_dial) do
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
                    expect_call_status_update(:cassette => :dial_no_action, :to => number_to_dial) do
                      subject.run
                    end
                  end
                end
              end

              context "specified" do
                # From: http://www.twilio.com/docs/api/twiml/dial

                # "The 'action' attribute takes a URL as an argument.
                # When the dialed call ends, Twilio will make a GET or POST
                # request to this URL including the parameters below.

                # "If you provide an 'action' URL, Twilio will continue the current call
                # after the dialed party has hung up, using the TwiML
                # received in your response to the 'action' URL request.
                # Any TwiML verbs occurring after a which specifies an 'action' attribute are unreachable."

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

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial action="http://localhost:3000/some_other_endpoint.xml">+415-123-4567</Dial>
                #   <Play>foo.mp3</Play>
                # </Response

                def expect_call_status_update(options = {}, &block)
                  super({
                    :cassette => :dial_hangup_with_action,
                    :action => redirect_url}.merge(options), &block
                  )
                end

                it "should send a POST request to the 'action' param and stop continuing with the current TwiML" do
                  subject.should_not_receive(:play_audio)
                  subject.should_receive(:hangup)
                  expect_call_status_update do
                    subject.run
                  end
                  last_request(:url).should == redirect_url
                  last_request(:method).downcase.should == default_config[:voice_request_method]
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

                      it "should post a DialCallStatus of '#{twilio_status}'" do
                        expect_call_status_update do
                          subject.run
                        end
                        assert_voice_request_params("DialCallStatus" => twilio_status)
                      end
                    end
                  end
                end

                describe "'method'" do
                  context "'GET'" do
                    # From: http://www.twilio.com/docs/api/twiml/dial

                    # <?xml version="1.0" encoding="UTF-8"?>
                    # <Response>
                    #   <Dial action="http://localhost:3000/some_other_endpoint.xml" method="GET">
                    #     +415-123-4567
                    #   </Dial>
                    # </Response

                    it "should send a 'GET' request to the 'action' param" do
                      expect_call_status_update(:cassette => :dial_with_get_action, :action_method => alternate_redirect_method) do
                        subject.run
                      end
                      last_request(:method).downcase.should == alternate_redirect_method
                    end
                  end
                end
              end
            end

            describe "'callerId'" do
              # From: http://www.twilio.com/docs/api/twiml/dial

              # "The 'callerId' attribute lets you specify the caller ID that will appear
              # to the called party when Twilio calls. By default,
              # when you put a <Dial> in your TwiML response to Twilio's inbound call request,
              # the caller ID that the dialed party sees is the inbound caller's caller ID."

              # "For example, an inbound caller to your Twilio number has the caller ID 1-415-123-4567.
              # You tell Twilio to execute a <Dial> verb to 1-858-987-6543 to handle the inbound call.
              # The called party (1-858-987-6543) will see 1-415-123-4567 as the caller ID
              # on the incoming call."

              # "If you are dialing to a <Client>, you can set a client identifier
              # as the callerId attribute. For instance, if you've set up a client
              # for incoming calls and you are dialing to it, you could set the callerId
              # attribute to client:tommy."

              # "If you are dialing a phone number from a Twilio Client connection,
              # you must specify a valid phone number as the callerId or the call will fail."

              # "You are allowed to change the phone number that the called party
              # sees to one of the following:"

              # - either the 'To' or 'From' number provided in Twilio's TwiML request to your app
              # - any incoming phone number you have purchased from Twilio
              # - any phone number you have verified with Twilio

              # | Attribute | Allowed Values                             | Default Value     |
              # | callerId  | a valid phone number, or client identifier | Caller's callerId |
              # |           | if you are dialing a <Client>.             |                   |

              context "specified" do
                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial callerId="2442">+415-123-4567</Dial>
                # </Response

                let(:caller_id) { "2442" }

                it "should dial from the specified 'callerId'" do
                  assert_dial(:from => caller_id)
                  expect_call_status_update(:cassette => :dial_with_caller_id, :caller_id => caller_id) do
                    subject.run
                  end
                end
              end

              context "not specified" do
                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial>+415-123-4567</Dial>
                # </Response

                it "should not dial with any callerId" do
                  assert_dial(:from => nil)
                  expect_call_status_update(:cassette => :dial_no_action) do
                    subject.run
                  end
                end
              end
            end

            describe "'timeout'" do
              # From: http://www.twilio.com/docs/api/twiml/dial

              # "The 'timeout' attribute sets the limit in seconds that <Dial>
              # waits for the called party to answer the call.
              # Basically, how long should Twilio let the call ring before giving up and
              # reporting 'no-answer' as the 'DialCallStatus'."

              # | Attribute | Allowed Values   | Default Value |
              # | timeout   | positive integer | 30 seconds    |

              context "specified" do
                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Dial timeout="10">+415-123-4567</Dial>
                # </Response

                let(:timeout) { "10" }

                it "should dial with the specified 'timeout'" do
                  assert_dial(:for => timeout.to_i.seconds)
                  expect_call_status_update(:cassette => :dial_with_timeout, :timeout => timeout) do
                    subject.run
                  end
                end
              end

              context "not specified" do
                it "should dial with a timeout of 30.seconds" do
                  assert_dial(:for => 30.seconds)
                  expect_call_status_update(:cassette => :dial_no_action) do
                    subject.run
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
