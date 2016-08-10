require 'spec_helper'

describe Adhearsion::Twilio::ControllerMethods, :type => :call_controller do

  describe "<Play>" do
    # From: http://www.twilio.com/docs/api/twiml/play

    # "The <Play> verb plays an audio file back to the caller.
    # Twilio retrieves the file from a URL that you provide."

    let(:cassette) { :play }
    let(:asserted_verb) { :play_audio }
    let(:asserted_verb_args) { [file_url, hash_including(asserted_verb_options)] }

    def setup_scenario
      allow(subject).to receive(:play_audio)
    end

    def cassette_options
      super.merge(:file_url => file_url)
    end

    before do
      setup_scenario
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

        it { run_and_assert! }
      end # context "plain text"
    end # describe "Nouns"

    describe "Verb Attributes" do
      # From: http://www.twilio.com/docs/api/twiml/play

      # The <Play> verb supports the following attributes that modify its behavior:

      # | Attribute Name | Allowed Values | Default Value |
      # | loop           | integer >= 0   | 1             |

      describe "'loop'" do
        # From: http://www.twilio.com/docs/api/twiml/play

        # The 'loop' attribute specifies how many times the audio file is played.
        # The default behavior is to play the audio once.
        # Specifying '0' will cause the the <Play> verb to loop until the call is hung up.

        context "not specified" do
          # From: http://www.twilio.com/docs/api/twiml/play

          # "The default behavior is to play the audio once."

          # <?xml version="1.0" encoding="UTF-8" ?>
          # <Response>
          #   <Play>http://api.twilio.com/cowbell.mp3</Play>
          # </Response>

          it { run_and_assert! }
        end # context "not specified"

        context "specified" do
          let(:cassette) { :play_with_loop }

          def cassette_options
            super.merge(:loop => loop)
          end

          context "'0'" do
            # From: http://www.twilio.com/docs/api/twiml/play

            # "Specifying '0' will cause the the <Play> verb to loop until the call is hung up."

            # <?xml version="1.0" encoding="UTF-8" ?>
            # <Response>
            #   <Play loop="0">http://api.twilio.com/cowbell.mp3</Play>
            # </Response>

            let(:loop) { "0" }
            let(:asserted_verb_num_runs) { infinity }

            def setup_scenario
              super
              stub_infinite_loop
            end

            it { run_and_assert! }
          end # context "'0'"

          context "'5'" do
            # From: http://www.twilio.com/docs/api/twiml/play

            # "The 'loop' attribute specifies how many times the audio file is played."

            # <?xml version="1.0" encoding="UTF-8" ?>
            # <Response>
            #   <Play loop="5">http://api.twilio.com/cowbell.mp3</Play>
            # </Response>

            let(:loop) { "5" }
            let(:asserted_verb_num_runs) { 5 }

            it { run_and_assert! }
          end # context "'5'"
        end # context "specified"
      end # describe "'loop'"
    end # describe "Verb Attributes"
  end # describe "<Play>"
end
