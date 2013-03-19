require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include FakeWebHelpers

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

        let(:alternate_redirect_method) { "get" }

        before do
          subject.stub(:hangup)
          call.stub(:alive?)
        end

        subject { TestController.new(call) }

        def default_config
          {
            :voice_request_url => ENV["AHN_TWILIO_VOICE_REQUEST_URL"] || "http://localhost:3000/",
            :voice_request_method => ENV["AHN_TWILIO_VOICE_REQUEST_METHOD"] || "post",
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

          last_request_body.each do |param, value|
            value.should == options[param]
          end
        end

        describe "posting call status updates" do
          it "should post the correct parameters to the call status voice request url" do
            expect_call_status_update { subject.run }
            assert_voice_request_params
          end
        end

        describe "hanging up" do
          # http://www.twilio.com/docs/api/twiml/hangup
          #
          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Hangup/>
          # </Response>

          it "should hang up the call" do
            subject.should_receive(:hangup)
            expect_call_status_update { subject.run }
          end
        end

        describe "redirecting" do
          # http://www.twilio.com/docs/api/twiml/redirect

          context "with no url" do
            # Note: this feature is not implemented in twilio

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Redirect/>
            # </Response>

            it "should redirect to the default voice request url" do
              expect_call_status_update(:cassette => :redirect_no_url) { subject.run }
              last_request.path.should == URI.parse(default_config[:voice_request_url]).path
              last_request.method.downcase.should == default_config[:voice_request_method]
            end
          end

          context "with a url" do
            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Redirect>"http://localhost:3000/some_other_endpoint.xml"</Redirect>
            # </Response>

            it "should redirect to the specified url" do
              expect_call_status_update(:cassette => :redirect_with_url, :redirect_url => redirect_url) do
                subject.run
              end
              last_request.path.should == URI.parse(redirect_url).path
              last_request.method.downcase.should == default_config[:voice_request_method]
            end

            context "and a GET method" do
              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Redirect method="GET">"http://localhost:3000/some_other_endpoint.xml"</Redirect>
              # </Response>

              it "should redirect to the specified url using a 'GET' request" do
                expect_call_status_update(:cassette => :redirect_with_get_url, :redirect_url => redirect_url, :redirect_method => alternate_redirect_method) do
                  subject.run
                end
                last_request.method.downcase.should == alternate_redirect_method
              end
            end
          end
        end

        describe "dialing" do
          # http://www.twilio.com/docs/api/twiml/dial

          def stub_dial_status(status)
            dial_status.stub(:result).and_return(status)
          end

          let(:number_to_dial) { "+415-123-4567" }
          let(:dial_status) { mock(Adhearsion::CallController::DialStatus, :result => :answer ) }

          before do
            subject.stub(:dial).and_return(dial_status)
          end

          context "to a number" do
            it "should dial to the specified number" do
              subject.should_receive(:dial).with(number_to_dial, {})
              expect_call_status_update(:cassette => :dial_no_action, :to => number_to_dial) do
                subject.run
              end
            end
          end

          context "without specifying an action" do
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

            context "and with no next verb" do
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

          context "specifying an action" do
            # From: http://www.twilio.com/docs/api/twiml/dial

            # "The 'action' attribute takes a URL as an argument.
            # When the dialed call ends, Twilio will make a GET or POST
            # request to this URL including the parameters below.

            # If you provide an 'action' URL, Twilio will continue the current call
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
                :to => number_to_dial, :action => redirect_url}.merge(options), &block
              )
            end

            it "should send a POST' request to the 'action' param and stop continuing with the current TwiML" do
              subject.should_not_receive(:play_audio)
              subject.should_receive(:hangup)
              expect_call_status_update do
                subject.run
              end
              last_request.path.should == URI.parse(redirect_url).path
              last_request.method.downcase.should == default_config[:voice_request_method]
            end

            context "and specifying a 'GET' method" do
              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Dial action="http://localhost:3000/some_other_endpoint.xml" method="GET">
              #     +415-123-4567
              #   </Dial>
              # </Response
              it "should send a 'GET' request to te 'action' param" do
                expect_call_status_update(:cassette => :dial_with_get_action, :action_method => alternate_redirect_method) do
                  subject.run
                end
                last_request.method.downcase.should == alternate_redirect_method
              end
            end

            context "where the Adhearsion dial status is" do
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
          end
        end
      end
    end
  end
end
