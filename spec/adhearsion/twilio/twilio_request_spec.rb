require 'spec_helper'

describe Adhearsion::Twilio::ControllerMethods, :type => :call_controller do
  describe "twilio request" do
    # From: http://www.twilio.com/docs/api/twiml/twilio_request

    # Twilio makes HTTP requests to your application just like a regular web browser.
    # By including parameters and values in its requests,
    # Twilio sends data to your application that you can act upon before responding.
    # You can configure the URLs and HTTP Methods Twilio uses to make its requests
    # via the account portal or using the REST API.

    # Creating a Twilio Application within your account will allow you to more-easily
    # configure the URLs you want Twilio to request when receiving a voice call to one
    # of your phone numbers. Instead of assigning URLs directly to a phone number,
    # you can assign them to an application and then assign that application to the
    # phone number. This will allow you to pass around configuration between phone numbers
    # without having to memorize or copy and paste URLs.

    let(:request_types) do
      {
        :voice_request => {
          :url_type => :voice_request,
          :cassette => :hangup
        },
        :status_callback_request => {
          :url_type => :status_callback,
          :cassette => :hangup_with_status_callback_url_set
        }
      }
    end

    let(:auth_token) { Adhearsion::Twilio::Configuration::DEFAULT_AUTH_TOKEN }
    let(:request_validator) { ::Adhearsion::Twilio::Util::RequestValidator.new(auth_token) }

    let(:http_request) { WebMock.requests.last }
    let(:http_request_params) { WebMock.request_params(http_request) }
    let(:request_url) { http_request.uri.to_s }
    let(:request_signature) { http_request.headers["X-Twilio-Signature"] }
    let(:cassette) { request_type[:cassette] }

    def setup_scenario
    end

    def assert_requests!
      expect(request_validator.validate(request_url, http_request_params, request_signature)).to eq(true)
    end

    def assert_call_controller_assertions!
    end

    def run!
      subject.execute!
    end

    before do
      setup_scenario
    end

    describe "#notify_voice_request_url" do
      let(:request_type) { request_types[:voice_request] }

      def assert_requests!
        super
        expect(http_request_params["CallStatus"]).to eq("ringing")
      end

      it { run_and_assert! }
    end

    context "overriding auth_token" do
      let(:auth_token) { "my_auth_token" }
      let(:metadata) { { :auth_token => auth_token } }
      let(:request_type) { request_types[:voice_request] }

      it { run_and_assert! }
    end

    context "configuration" do
      def setup_scenario
        super
        set_dummy_url_config(request_type[:url_type], configuration_name, configuration_value)
      end

      context "method" do
        let(:configuration_name) { :method }
        let(:asserted_value) { configuration_value }

        def setup_scenario
          super
          set_dummy_url_config(request_type[:url_type], :url, redirect_url)
        end

        def assert_requests!
          super
          expect(http_request.method).to eq(asserted_value)
        end

        context "POST" do
          let(:configuration_value) { :post }

          context "Voice Request" do
            let(:request_type) { request_types[:voice_request] }
            it { run_and_assert! }

            context "with overriding metadata" do
              let(:metadata) { {:voice_request_method => :get} }
              let(:asserted_value) { :get }

              def cassette_options
                super.merge(:method => asserted_value)
              end

              it { run_and_assert! }
            end
          end

          context "Status Callback Request" do
            let(:request_type) { request_types[:status_callback_request] }
            it { run_and_assert! }

            context "with overriding metadata" do
              let(:metadata) { {:status_callback_method => :get} }
              let(:asserted_value) { :get }

              def cassette_options
                super.merge(:status_callback_method => asserted_value)
              end

              it { run_and_assert! }
            end
          end
        end

        context "GET" do
          let(:configuration_value) { :get }

          context "Voice Request" do
            let(:request_type) { request_types[:voice_request] }
            it { run_and_assert! }
          end

          context "Status Callback Request" do
            let(:request_type) { request_types[:status_callback_request] }
            it { run_and_assert! }
          end
        end
      end

      context "url" do
        let(:configuration_name) { :url }

        def assert_requests!
          super
          expect(http_request.uri.to_s).to eq(asserted_value)
        end

        context "without HTTP Basic" do
          let(:configuration_value) { "http://localhost:1234/endpoint.xml/" }
          let(:asserted_value) { configuration_value }

          def assert_requests!
            super
            expect(http_request.headers).not_to have_key("Authorization")
          end

          context "Voice Request" do
            let(:request_type) { request_types[:voice_request] }
            it { run_and_assert! }

            context "with overriding metadata" do
              let(:metadata) { {:voice_request_url => "http://override.bar.com:1234/"} }
              let(:asserted_value) { "http://override.bar.com:1234/" }

              def cassette_options
                super.merge(:url => asserted_value)
              end

              it { run_and_assert! }
            end
          end

          context "Status Callback Request" do
            let(:request_type) { request_types[:status_callback_request] }
            it { run_and_assert! }

            context "with overriding metadata" do
              let(:metadata) { {:status_callback_url => "http://override.bar.com:1234/"} }
              let(:asserted_value) { "http://override.bar.com:1234/" }

              def cassette_options
                super.merge(:status_callback_url => asserted_value)
              end

              it { run_and_assert! }
            end
          end
        end

        context "with HTTP Basic" do
          let(:configuration_value) { "http://user:password@localhost:1234/endpoint.xml/" }
          let(:asserted_value) { "http://localhost:1234/endpoint.xml/" }

          def assert_requests!
            super
            authorization = Base64.decode64(http_request.headers["Authorization"].sub(/^Basic\s/, ""))
            user, password = authorization.split(":")
            expect(user).to eq("user")
            expect(password).to eq("password")
          end

          context "Voice Request" do
            def cassette_options
              super.merge(:url => asserted_value)
            end

            let(:request_type) { request_types[:voice_request] }
            it { run_and_assert! }
          end

          context "Status Callback Request" do
            def cassette_options
              super.merge(:status_callback_url => asserted_value)
            end

            let(:request_type) { request_types[:status_callback_request] }
            it { run_and_assert! }
          end
        end
      end
    end

    describe "TwiML Voice Requests" do
      # From: http://www.twilio.com/docs/api/twiml/twilio_request

      # adhearsion-twilio configuration:
      # config.twilio.voice_request_url
      # config.twilio.voice_request_method

      # When Twilio receives a call for one of your Twilio numbers it makes a synchronous
      # HTTP request to the Voice URL configured for that number, and expects to receive
      # TwiML in response. Twilio sends the following parameters with its request as POST
      # parameters or URL query parameters, depending on which HTTP method you've configured:

      # Request Parameters

      # | Parameter     | Description                                                              |
      # |               |                                                                          |
      # | CallSid       | A unique identifier for this call, generated by Twilio.                  |
      # |               |                                                                          |
      # | AccountSid    | Your Twilio account id. It is 34 characters long,                        |
      # |               | and always starts with the letters AC.                                   |
      # |               |                                                                          |
      # | From          | The phone number or client identifier of the party                       |
      # |               | that initiated the call. Phone numbers are formatted                     |
      # |               | with a '+' and country code, e.g. +16175551212 (E.164 format).           |
      # |               | Client identifiers begin with the client: URI scheme; for example,       |
      # |               | for a call from a client named 'tommy', the From parameter               |
      # |               | will be client:tommy.                                                    |
      # |               |                                                                          |
      # | To            | The phone number or client identifier of the called party.               |
      # |               | Phone numbers are formatted with a '+' and country code,                 |
      # |               | e.g. +16175551212 (E.164 format). Client identifiers begin with          |
      # |               | the client: URI scheme; for example, for a call to a client named        |
      # |               |                                                                          |
      # |               | 'jenny', the To parameter will be client:jenny.                          |
      # | CallStatus    | A descriptive status for the call. The value is one of queued,           |
      # |               | ringing, in-progress, completed, busy, failed or no-answer.              |
      # |               | See the CallStatus section below for more details.                       |
      # |               |                                                                          |
      # | ApiVersion    | The version of the Twilio API used to handle this call.                  |
      # |               | For incoming calls, this is determined by the API version                |
      # |               | set on the called number. For outgoing calls, this is the                |
      # |               | API version used by the outgoing call's REST API request.                |
      # |               |                                                                          |
      # | Direction     | Indicates the direction of the call. In most cases this will be inbound, |
      # |               | but if you are using <Dial> it will be outbound-dial.                    |
      # |               |                                                                          |
      # | ForwardedFrom | This parameter is set only when Twilio receives a forwarded call,        |
      # |               | but its value depends on the caller's carrier including information      |
      # |               | when forwarding. Not all carriers support passing this information.      |
      # |               |                                                                          |
      # | CallerName    | This parameter is set when the IncomingPhoneNumber that received         |
      # |               | the call has had its VoiceCallerIdLookup value set to true               |
      # |               | ($0.01 per look up).                                                     |

      # Twilio also attempts to look up geographic data based on the 'To' and 'From'
      # phone numbers. The following parameters are sent, if available:

      # | Parameter   | Description                                |
      # | FromCity    | The city of the caller.                    |
      # | FromState   | The state or province of the caller.       |
      # | FromZip     | The postal code of the caller.             |
      # | FromCountry | The country of the caller.                 |
      # | ToCity      | The city of the called party.              |
      # | ToState     | The state or province of the called party. |
      # | ToZip       | The postal code of the called party.       |
      # | ToCountry   | The country of the called party.           |

      # Depending on the what is happening on a call, other variables may also be sent.
      # The individual TwiML verb sections have more details.

      # CallStatus Values

      # The following are the possible values for the 'CallStatus' parameter.
      # These values also apply to the 'DialCallStatus' parameter,
      # which is sent with requests to a <Dial> Verb's action URL.

      # | Status      | Description
      # | queued      | The call is ready and waiting in line before going out.         |
      # | ringing     | The call is currently ringing.                                  |
      # | in-progress | The call was answered and is currently in progress.             |
      # | completed   | The call was answered and has ended normally.                   |
      # | busy        | The caller received a busy signal.                              |
      # | failed      | The call could not be completed as dialed,                      |
      # |             | most likely because the phone number was non-existent.          |
      # | no-answer   | The call ended without being answered.                          |
      # | canceled    | The call was canceled via the REST API while queued or ringing. |

      let(:request_type) { request_types[:voice_request] }
      it { run_and_assert! }
    end # describe "TwiML Voice Requests"

    describe "Call End Callback (StatusCallback) Requests" do
      # From: http://www.twilio.com/docs/api/twiml/twilio_request

      # adhearsion-twilio configuration:
      # config.twilio.status_callback_url
      # config.twilio.status_callback_method

      # After receiving a call, requesting TwiML from your app, processing it,
      # and finally ending the call, Twilio will make an asynchronous HTTP request
      # to the StatusCallback URL configured for the called Twilio number (if there is one).
      # By providing a StatusCallback URL for your Twilio number and capturing this
      # request you can determine when a call ends and receive information about the call.

      # Request Parameters

      # The parameters Twilio passes to your application in an asynchronous request
      # to the StatusCallback URL include all those passed in a synchronous TwiML request.

      # The Status Callback request also passes these additional parameters:

      # | Parameter         | Description                                              |
      # |                   |                                                          |
      # | CallDuration      | The duration in seconds of the just-completed call.      |
      # |                   |                                                          |
      # | RecordingUrl      | The URL of the phone call's recorded audio.              |
      # |                   | This parameter is included only if Record=true is set on |
      # |                   | the REST API request,                                    |
      # |                   | and does not include recordings from <Dial> or <Record>. |
      # |                   |                                                          |
      # | RecordingSid      | The unique id of the Recording from this call.           |
      # |                   |                                                          |
      # | RecordingDuration | The duration of the recorded audio (in seconds).         |

      let(:request_type) { request_types[:status_callback_request] }

      context "is not configured" do
        # Twilio will make an asynchronous HTTP request
        # to the StatusCallback URL configured for the called Twilio number (if there is one).
        it { run_and_assert! }
      end

      context "is configured" do
        def setup_scenario
          super
          set_dummy_url_config(:status_callback, :url, redirect_url)
        end

        context "when the call is hungup" do
          def setup_scenario
            super
            allow(mock_call).to receive(:duration).and_return(61.5)
          end

          def assert_requets!
            assert_voice_request_params(
              "CallStatus" => "no-answer",
              "CallDuration" => "61",
              :request_position => :last
            )
          end

          it { run_and_assert! }
        end # context "when the call is hungup"
      end # context "is configured"
    end # describe "Call End Callback (StatusCallback) Requests"
  end # describe "twilio request"
end
