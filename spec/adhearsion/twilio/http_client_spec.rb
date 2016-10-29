require 'spec_helper'

describe Adhearsion::Twilio::HttpClient do
  include MockCall
  include LoggingHelpers

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

  def setup_scenario
    WebMock.clear_requests!
    silence_logging!
  end

  def expect_http_request!(&block)
    VCR.use_cassette(:hangup, :erb => {:url => request_url, :method => request_method}) do
      yield
    end
  end

  before do
    setup_scenario
  end

  let(:voice_request_url) { "https://voice-request.com/twiml.xml" }
  let(:voice_request_method) { "POST" }
  let(:status_callback_url) { nil }
  let(:status_callback_method) { nil }
  let(:call_from) { "+85512345678" }
  let(:call_to) { "+85512345679" }
  let(:call_sid) { "abcdefg" }
  let(:call_direction) { nil }
  let(:auth_token) { "some_auth_token" }

  subject {
    described_class.new(
      :voice_request_url => voice_request_url,
      :voice_request_method => voice_request_method,
      :status_callback_url => status_callback_url,
      :status_callback_method => status_callback_method,
      :call_sid => call_sid,
      :call_from => call_from,
      :call_to => call_to,
      :call_direction => call_direction,
      :auth_token => auth_token,
      :logger => logger
    )
  }

  let(:http_request_params) { WebMock.request_params(http_request) }
  let(:http_request) { WebMock.requests.last }

  shared_examples_for "authorization_header" do
    context "Authorization Header" do
      def setup_scenario
        subject.public_send(:"#{request_url_method}=", authorization_request_url)
        super
      end

      context "without HTTP Basic Auth specified in the URL" do
        let(:authorization_request_url) { "https://voice-request.com:1234/twiml.xml" }

        def assert_request!
          expect(http_request.headers).not_to have_key("Authorization")
        end

        it { assert_request! }
      end

      context "with HTTP Basic Auth specified in the URL" do
        let(:request_url) { "https://voice-request.com:1234/twiml.xml" }
        let(:authorization_request_url) { "https://user:password@voice-request.com:1234/twiml.xml" }

        def assert_request!
          authorization = Base64.decode64(http_request.headers["Authorization"].sub(/^Basic\s/, ""))
          user, password = authorization.split(":")
          expect(user).to eq("user")
          expect(password).to eq("password")
        end

        it { assert_request! }
      end
    end
  end

  shared_examples_for "http_method" do
    context "HTTP method" do
      def assert_request!
        expect(http_request.method).to eq(asserted_http_method)
      end

      def setup_scenario
        subject.public_send(:"#{request_url_http_method}=", http_method_request_method)
        super
      end

      context "POST" do
        let(:http_method_request_method) { "POST" }
        let(:asserted_http_method) { :post }
        it { assert_request! }
      end

      context "GET" do
        let(:http_method_request_method) { "GET" }
        let(:asserted_http_method) { :get }

        it { assert_request! }
      end
    end
  end

  shared_examples_for "request_signature" do
    context "Request Signature" do
      let(:request_validator) { ::Adhearsion::Twilio::Util::RequestValidator.new(auth_token) }
      let(:request_signature) { http_request.headers["X-Twilio-Signature"] }

      def assert_request!
        expect(
          request_validator.validate(
            request_url, http_request_params, request_signature
          )
        ).to eq(true)
      end

      context "default auth token" do
        let(:auth_token) { Adhearsion::Twilio::Configuration::DEFAULT_AUTH_TOKEN }
        it { assert_request! }
      end

      context "custom auth token" do
        let(:auth_token) { "my_auth_token" }
        it { assert_request! }
      end
    end
  end

  shared_examples_for "call_direction" do
    context "Direction" do
      def assert_request!
        expect(http_request_params["Direction"]).to eq(asserted_direction)
      end

      context "for inbound calls" do
        let(:asserted_direction) { "inbound" }
        it { assert_request! }
      end

      context "for outbound calls" do
        let(:call_direction) { :outbound_api }
        let(:asserted_direction) { "outbound-api" }
        it { assert_request! }
      end
    end
  end

  shared_examples_for "http_body" do
    context "HTTP Body" do
      def assert_request!
        expect(http_request_params).to have_key("CallStatus")
        expect(http_request_params).to have_key("Direction")
        expect(http_request_params).to have_key("ApiVersion")
        expect(http_request_params["From"]).to eq(call_from)
        expect(http_request_params["To"]).to eq(call_to)
        expect(http_request_params["CallSid"]).to eq(call_sid)
      end

      it { assert_request! }
    end
  end

  describe "#notify_voice_request_url" do
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

    let(:request_url_method) { :voice_request_url }
    let(:request_url_http_method) { :voice_request_method }
    let(:request_url) { subject.voice_request_url }
    let(:request_method) { subject.voice_request_method }

    def setup_scenario
      super
      expect_http_request! do
        subject.notify_voice_request_url
      end
    end

    context "CallStatus" do
      def assert_request!
        expect(http_request_params["CallStatus"]).to eq("ringing")
      end

      it { assert_request! }
    end

    include_examples "authorization_header"
    include_examples "http_method"
    include_examples "request_signature"
    include_examples "call_direction"
    include_examples "http_body"
  end

  describe "#notify_status_callback_url(status, options = {})" do
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

    let(:status_callback_url) { "https://voice-request.com/status_callback.xml" }
    let(:status_callback_method) { "POST" }

    let(:request_url_method) { :status_callback_url }
    let(:request_url_http_method) { :status_callback_method }

    let(:request_url) { subject.status_callback_url }
    let(:request_method) { subject.status_callback_method }
    let(:status) { :answered }
    let(:options) { {} }

    def do_notify_status_callback_url
      subject.notify_status_callback_url(status, options)
    end

    def setup_scenario
      super
      expect_http_request! do
        do_notify_status_callback_url
      end
    end

    context "CallDuration" do
      let(:options) { { "CallDuration" => "61" } }

      def assert_request!
        expect(http_request_params["CallDuration"]).to eq("61")
      end

      it { assert_request! }
    end

    context "CallStatus" do
      def assert_request!
        expect(http_request_params["CallStatus"]).to eq(asserted_call_status)
      end

      context "answer" do
        let(:status) { :answer }
        let(:asserted_call_status) { "completed" }
        it { assert_request! }
      end

      context "no_answer" do
        let(:status) { :no_answer }
        let(:asserted_call_status) { "no-answer" }
        it { assert_request! }
      end
    end

    context "status_callback_url is not set" do
      # Twilio will make an asynchronous HTTP request
      # to the StatusCallback URL configured for the called Twilio number (if there is one).

      let(:status_callback_url) { nil }

      def assert_request!
        expect(http_request).to eq(nil)
      end

      it { assert_request! }
    end

    include_examples "authorization_header"
    include_examples "http_method"
    include_examples "request_signature"
    include_examples "call_direction"
    include_examples "http_body"
  end
end
