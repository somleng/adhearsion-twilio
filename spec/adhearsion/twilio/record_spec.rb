require 'spec_helper'

describe Adhearsion::Twilio::ControllerMethods, :type => :call_controller do
  describe "<Record>" do
    # From: http://www.twilio.com/docs/api/twiml/record

    # The <Record> verb records the caller's voice and returns to you the URL of a file containing
    # the audio recording. You can optionally generate text transcriptions of recorded calls
    # by setting the 'transcribe' attribute of the <Record> verb to 'true'.

    let(:cassette) { :record }

    let(:recording_duration) { 0 }
    let(:non_zero_recording_duration) { 7019 }

    let(:asserted_verb) { :record }
    let(:asserted_start_beep) { true }
    let(:asserted_final_timeout) { 5 }
    let(:recording_uri) { "file://abcd.wav" }
    let(:rest_api_phone_call_event_recording_url) { "https://somleng.org/Recording/12345" }

    let(:recording) {
      instance_double(
        "Adhearsion::Rayo::Component::Record::Recording",
        :duration => recording_duration,
        :uri => recording_uri
      )
    }

    let(:record_component) {
      instance_double(
        "Adhearsion::Rayo::Component::Record",
        :recording => recording
      )
    }

    let(:recording_started_event) {
      instance_double(
        "Adhearsion::Twilio::Event::RecordingStarted"
      )
    }

    let(:rest_api_phone_call_event) {
      instance_double(
        "Adhearsion::Twilio::RestApi::PhoneCallEvent",
        :notify! => nil,
        :notify_response => notify_response
      )
    }

    let(:notify_response) {
      # cannot use instance double here because of method_missing
      double("HTTParty::Response")
    }

    # 1. Original TwiML request (zero recording duration)
    let(:asserted_requests_count) { 1 }
    let(:requests) { WebMock.requests }

    let(:call_id) { "call-id" }

    def call_params
      super.merge(:id => call_id)
    end

    def asserted_event_params
      {}
    end

    def asserted_verb_options
      {
        :start_beep => asserted_start_beep,
        :final_timeout => asserted_final_timeout
      }
    end

    def asserted_verb_args
      [asserted_verb_options]
    end

    def assert_verb!
      super
      expect(Adhearsion::Twilio::Event::RecordingStarted).to receive(:new).with(call_id, hash_including(asserted_event_params))
      expect(Adhearsion::Twilio::RestApi::PhoneCallEvent).to receive(:new).with(hash_including(:event => recording_started_event))
      expect(rest_api_phone_call_event).to receive(:notify!)
    end

    def assert_requests!
      super
      expect(requests.count).to eq(asserted_requests_count)
    end

    def setup_scenario
      allow(subject).to receive(:record).and_return(record_component)
      allow(Adhearsion::Twilio::Event::RecordingStarted).to receive(:new).and_return(recording_started_event)
      allow(Adhearsion::Twilio::RestApi::PhoneCallEvent).to receive(:new).and_return(rest_api_phone_call_event)
      allow(notify_response).to receive(:[]).with("recording_url").and_return(rest_api_phone_call_event_recording_url)
    end

    before do
      setup_scenario
    end

    it { run_and_assert! }

    describe "Verb Attributes" do
      # From: http://www.twilio.com/docs/api/twiml/record

      # The <Record> verb supports the following attributes that modify its behavior:

      # | Attribute Name                | Allowed Values            | Default Value        |
      # | action                        | relative or absolute URL  | current document URL |
      # | method                        | GET, POST                 | POST                 |
      # | timeout                       | positive integer          | 5                    |
      # | finishOnKey                   | any digit, #, *           | 1234567890*#         |
      # | maxLength                     | integer greater than 1    | 3600 (1 hour)        |
      # | playBeep                      | true, false               | true                 |
      # | trim                          | trim-silence, do-not-trim | trim-silence         |
      # | recordingStatusCallback       | relative or absolute URL  | none                 |
      # | recordingStatusCallbackMethod | GET, POST                 | POST                 |
      # | transcribe                    | true, false               | false                |
      # | transcribeCallback            | relative or absolute URL  | none                 |

      describe "'action'" do
        # From: https://www.twilio.com/docs/api/twiml/record#attributes-action

        # The 'action' attribute takes a relative or absolute URL as a value.
        # When recording is finished Twilio will make a GET or POST request to this URL
        # including the parameters below. If no 'action' is provided,
        # <Record> will default to requesting the current document's URL.

        # After making this request, Twilio will continue the current call
        # using the TwiML received in your response. Keep in mind that by default Twilio
        # will re-request the current document's URL, which can lead to unwanted
        # looping behavior if you're not careful.
        # Any TwiML verbs occurring after a <Record> are unreachable.

        # There is one exception: if Twilio receives an empty recording,
        # it will not make a request to the 'action' URL.
        # The current call flow will continue with the next verb in the current TwiML document.

        # From: https://www.twilio.com/docs/api/twiml/record#attributes-action-parameters

        # Request Parameters

        # Twilio will pass the following parameters in addition to the standard TwiML Voice
        # request parameters with its request to the 'action' URL:

        # | Parameter         | Description                                           |
        # |                   |                                                       |
        # | RecordingUrl      | The URL of the recorded audio.                        |
        # |                   | The recording file may not yet be accessible          |
        # |                   | when the 'action' callback is sent.                   |
        # |                   | Use recordingStatusCallback for reliable notification |
        # |                   | on when the recording is available for access.        |
        # |                   |                                                       |
        # | RecordingDuration | The duration of the recorded audio (in seconds).      |
        # |                   | To get a final accurate recording duration after any  |
        # |                   | trimming of silence, use recordingStatusCallback.     |
        # |                   |                                                       |
        # | Digits            | The key (if any) pressed to end the recording         |
        # |                   | or 'hangup' if the caller hung up                     |

        # A request to the RecordingUrl will return a recording in binary WAV audio
        # format by default. To request the recording in MP3 format,
        # append ".mp3" to the RecordingUrl.

        context "non-empty recording" do
          let(:recording_duration) { non_zero_recording_duration }

          let(:asserted_requests_count) { 2 }
          let(:action_request) { requests.last }
          let(:action_request_params) { WebMock.request_params(action_request) }
          let(:asserted_recording_duration) { non_zero_recording_duration / 1000 }
          let(:asserted_recording_url) { rest_api_phone_call_event_recording_url }

          def assert_requests!
            super
            expect(action_request_params["RecordingDuration"]).to eq(asserted_recording_duration.to_s)
            expect(action_request_params["RecordingUrl"]).to eq(asserted_recording_url)
            expect(action_request_params).not_to have_key("Digits") # Not Implemented
          end

          context "not specified" do
            let(:cassette) { :record_with_result }

            def cassette_options
              super.merge(:redirect_url => current_config[:voice_request_url])
            end

            # From: https://www.twilio.com/docs/api/twiml/record#attributes-action

            # If no 'action' is provided, <Record> will default to
            # requesting the current document's URL.

            # Given the following example:

            # <?xml version="1.0" encoding="UTF-8" ?>
            # <Response>
            #   <Record/>
            # </Response>

            def assert_requests!
              super
              expect(action_request.uri.to_s).to eq(current_config[:voice_request_url])
            end

            it { run_and_assert! }

            context "no recording_url is returned by the REST API" do
              let(:asserted_recording_url) { recording_uri }
              let(:rest_api_phone_call_event_recording_url) { nil }

              it { run_and_assert! }
            end
          end

          context "specified" do
            let(:cassette) { :record_with_action }

            # From: https://www.twilio.com/docs/api/twiml/record#attributes-action

            # The 'action' attribute takes a relative or absolute URL as a value.
            # When recording is finished Twilio will make a GET or POST request to this URL.

            # Given the following examples:

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Record action="http://localhost:3000/some_other_endpoint.xml"/>
            # </Response>

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Record action="../relative_endpoint.xml"/>
            # </Response>

            it_should_behave_like "a TwiML 'action' attribute"
          end
        end

        context "empty recording" do
          # From: https://www.twilio.com/docs/api/twiml/record#attributes-action

          # There is one exception: if Twilio receives an empty recording,
          # it will not make a request to the 'action' URL.
          # The current call flow will continue with the next verb in the current TwiML document.

          let(:recording_duration) { 0 }
          let(:cassette) { :record_then_play }
          let(:asserted_requests_count) { 1 }

          def assert_call_controller_assertions!
            super
            assert_next_verb_reached!
          end

          it { run_and_assert! }
        end
      end

      describe "'method'" do
        let(:recording_duration) { non_zero_recording_duration }
        let(:asserted_requests_count) { 2 }

        # From: https://www.twilio.com/docs/api/twiml/record#attributes-method

        # The 'method' attribute takes the value 'GET' or 'POST'.
        # This tells Twilio whether to request the 'action' URL via HTTP GET or POST.
        # This attribute is modeled after the HTML form 'method' attribute.
        # 'POST' is the default value.

        # Given the following examples:

        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Record/>
        # </Response>

        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Record method="GET"/>
        # </Response>

        # <?xml version="1.0" encoding="UTF-8"?>
        # <Response>
        #   <Record method="POST"/>
        # </Response>

        it_should_behave_like "a TwiML 'method' attribute" do
          let(:without_method_cassette) { :record_with_action }
          let(:with_method_cassette) { :record_with_action_and_method }
        end
      end # describe "'method'"

      describe "'timeout'" do
        # From: https://www.twilio.com/docs/api/twiml/record#attributes-timeout

        # The 'timeout' attribute tells Twilio to end the recording
        # after a number of seconds of silence has passed. The default is 5 seconds.

        # From: https://github.com/adhearsion/adhearsion/blob/develop/lib/adhearsion/call_controller/record.rb

        # :final_timeout Controls the length (seconds) of a period of
        # silence after callers have spoken to conclude they finished.

        context "not specified" do
          # Given the following example:

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Record/>
          # </Response>

          it { run_and_assert! }
        end

        context "specified" do
          let(:cassette) { :record_with_timeout }

          def cassette_options
            super.merge(:timeout => timeout)
          end

          context "'10'" do
            # Given the following example:

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Record timeout='10'/>
            # </Response>

            let(:timeout) { 10 }
            let(:asserted_final_timeout) { timeout }
            it { run_and_assert! }
          end
        end
      end # describe "'timeout'"

      describe "'playBeep'" do
        # From: https://www.twilio.com/docs/api/twiml/record#attributes-playBeep

        # The 'playBeep' attribute allows you to toggle between playing a sound
        # before the start of a recording.
        # If you set the value to 'false', no beep sound will be played.

        context "not specified" do
          # Given the following example:

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Record/>
          # </Response>

          it { run_and_assert! }
        end

        context "specified" do
          let(:cassette) { :record_with_play_beep }

          def cassette_options
            super.merge(:play_beep => play_beep)
          end

          context "'true'" do
            # Given the following example:

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Record playBeep='true'/>
            # </Response>

            let(:play_beep) { true }
            it { run_and_assert! }
          end

          context "'false'" do
            # Given the following example:

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Record playBeep='false'/>
            # </Response>

            let(:play_beep) { false }
            let(:asserted_start_beep) { false }
            it { run_and_assert! }
          end
        end
      end # describe "'playBeep'"

      describe "'recordingStatusCallback'" do
        # From: # https://www.twilio.com/docs/api/twiml/record#attributes-recording-status-callback

        # The 'recordingStatusCallback' attribute takes a relative or absolute URL
        # as an argument. If a 'recordingStatusCallback' URL is given,
        # Twilio will make a GET or POST request to the specified URL when the recording
        # is available to access.

        # Request Parameters

        # Twilio will pass the following parameters with its request to the
        # 'recordingStatusCallback' URL:

        # | Parameter         | Description                                           |
        # |                   |                                                       |
        # | AccountSid        | The unique identifier of the Account                  |
        # |                   | responsible for this recording.                       |
        # |                   |                                                       |
        # | CallSid           | A unique identifier for the call associated           |
        # |                   | with the recording.                                   |
        # |                   |                                                       |
        # |                   | To get a final accurate recording duration after any  |
        # |                   | trimming of silence, use recordingStatusCallback.     |
        # |                   |                                                       |
        # | RecordingSid      | he URL of the recorded audio.                         |
        # |                   |                                                       |
        # | RecordingUrl      | The unique identifier for the recording.              |
        # |                   |                                                       |
        # | RecordingStatus   | The status of the recording.                          |
        # |                   | Possible values are: completed.                       |
        # |                   |                                                       |
        # | RecordingDuration | The length of the recording, in seconds.              |
        # |                   |                                                       |
        # | RecordingChannels | The number of channels in the final recording         |
        # |                   | file as an integer.                                   |
        # |                   | Only 1 channel is supported for the <Record> verb.    |
        # |                   |                                                       |
        # | RecordingSource   | The type of call that created this recording.         |
        # |                   | RecordVerb is returned for recordings                 |
        # |                   | initiated via the <Record> verb.                      |

        context "specified" do
          let(:cassette) { :record_with_recoding_status_callback }

          def asserted_event_params
            super.merge("recordingStatusCallback" => asserted_recording_status_callback)
          end

          def cassette_options
            super.merge(:recording_status_callback => recording_status_callback)
          end

          context "absolute url" do
            # Given the following example:

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Record recordingStatusCallback='https://somleng.org/recording_status_callback'/>
            # </Response>

            let(:recording_status_callback) { "https://somleng.org/recording_status_callback" }
            let(:asserted_recording_status_callback) { recording_status_callback }
            it { run_and_assert! }
          end

          context "relative url" do
            # Given the following example:

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Record recordingStatusCallback=/recording_status_callback'/>
            # </Response>

            let(:recording_status_callback) { "/recording_status_callback" }
            let(:asserted_recording_status_callback) {
              URI.join(default_config[:voice_request_url], recording_status_callback).to_s
            }

            it { run_and_assert! }
          end
        end

        context "not specified" do
          # Given the following example:

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Record/>
          # </Response>

          it { run_and_assert! }
        end
      end # describe "'recordingStatusCallback'"

      describe "'recordingStatusCallbackMethod'" do
        #From: https://www.twilio.com/docs/api/twiml/record#attributes-recording-status-callback-method

        # This attribute indicates which HTTP method to use when
        # requesting 'recordingStatusCallback'. It defaults to 'POST'.

        context "specified" do
          # Given the following example:

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Record recordingStatusCallbackMethod='GET'/>
          # </Response>

          let(:recording_status_callback_method) { "GET" }
          let(:cassette) { :record_with_recoding_status_callback_method }

          def asserted_event_params
            super.merge("recordingStatusCallbackMethod" => recording_status_callback_method)
          end

          def cassette_options
            super.merge(:recording_status_callback_method => recording_status_callback_method)
          end

          it { run_and_assert! }
        end

        context "not specified" do
          # Given the following example:

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Record/>
          # </Response>

          it { run_and_assert! }
        end
      end # describe "'recordingStatusCallbackMethod'"
    end # describe "Verb Attributes"
  end # describe "<Record>"
end
