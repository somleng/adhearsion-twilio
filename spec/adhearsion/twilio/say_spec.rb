require 'spec_helper'

describe Adhearsion::Twilio::ControllerMethods, :type => :call_controller do
  describe "<Say>" do
    # http://www.twilio.com/docs/api/twiml/say

    # The <Say> verb converts text to speech that is read back to the caller.
    # <Say> is useful for development or saying dynamic text that is difficult to pre-record.

    let(:cassette) { :say }
    let(:asserted_verb) { :say }
    let(:asserted_verb_args) { [words, hash_including(asserted_verb_options)] }

    before do
      setup_scenario
    end

    def setup_scenario
    end

    def cassette_options
      super.merge(:words => words)
    end

    describe "Nouns" do
      # From: http://www.twilio.com/docs/api/twiml/say

      # The "noun" of a TwiML verb is the stuff nested within the verb
      # that's not a verb itself; it's the stuff the verb acts upon.
      # These are the nouns for <Say>:

      # | Noun        | Description                              |
      # | plain text  | The text Twilio will read to the caller. |
      # |             | Limited to 4KB (4,000 ASCII characters)  |

      context "plain text" do
        # <?xml version="1.0" encoding="UTF-8" ?>
        # <Response>
        #    <Say>Hello World</Say>
        # </Response>

        it { run_and_assert! }
      end
    end

    describe "Verb Attributes" do
      # From: http://www.twilio.com/docs/api/twiml/say

      # The <Say> verb supports the following attributes that modify its behavior:

      # | Attribute Name | Allowed Values            | Default Value |
      # | voice          | man, woman                | man           |
      # | language       | en, en-gb, es, fr, de, it | en            |
      # | loop           | integer >= 0              | 1             |

      describe "'voice' (Differs from Twilio)" do
        # From: http://www.twilio.com/docs/api/twiml/say

        # The 'voice' attribute allows you to choose
        # a male or female voice to read text back. The default value is 'man'.

        # | Attribute Name | Allowed Values | Default Value |
        # | voice          | man, woman     | man           |

        def setup_scenario
          set_dummy_voices
        end

        let(:voice) { current_config[:default_male_voice] }
        let(:asserted_verb_options) { { :voice => voice } }

        context "not specified" do
          # From: http://www.twilio.com/docs/api/twiml/say

          # "The default value is 'man'."

          # Note: The behaviour differs here from the behaviour or Twilio.
          # If the voice attribute is not specified, it will default to
          # AHN_TWILIO_DEFAULT_MALE_VOICE or config.twilio.default_male_voice

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Say>Hello World</Say>
          # </Response>

          it { run_and_assert! }
        end

        context "specified" do
          # From: http://www.twilio.com/docs/api/twiml/say

          # "The 'voice' attribute allows you to choose
          # a male or female voice to read text back."

          let(:cassette) { :say_with_voice }

          context "'man'" do
            # From: http://www.twilio.com/docs/api/twiml/say

            # "The 'voice' attribute allows you to choose
            # a male voice to read text back."

            # Note: The behaviour differs here from the behaviour or Twilio.
            # If the voice attribute is 'man' it will default to
            # AHN_TWILIO_DEFAULT_MALE_VOICE or config.twilio.default_male_voice

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Say voice="man">Hello World</Say>
            # </Response>

            def cassette_options
              super.merge(:voice => "man")
            end

            it { run_and_assert! }
          end

          context "'woman'" do
            # From: http://www.twilio.com/docs/api/twiml/say

            # "The 'voice' attribute allows you to choose
            # a female voice to read text back."

            # Note: The behaviour differs here from the behaviour or Twilio.
            # If the voice attribute is 'woman' it will default to
            # AHN_TWILIO_DEFAULT_FEMALE_VOICE or config.twilio.default_female_voice

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Say voice="woman">Hello World</Say>
            # </Response>

            def cassette_options
              super.merge(:voice => "woman")
            end

            let(:voice) { current_config[:default_female_voice] }
            it { run_and_assert! }
          end
        end
      end

      describe "language (Differs from Twilio)" do
        # From: http://www.twilio.com/docs/api/twiml/say

        # The 'language' attribute allows you pick a voice with a
        # specific language's accent and pronunciations.
        # Twilio currently supports English with an American accent (en),
        # English with a British accent (en-gb), Spanish (es), French (fr),
        # Italian (it), and German (de).
        # The default is English with an American accent (en).

        # Note: this behaviour differs from Twilio.
        # The language option is not yet supported in adhearsion-twilio
        # so the option is ignored

        context "not specified" do
          # From: http://www.twilio.com/docs/api/twiml/say

          # "The default is English with an American accent (en)."

          # <?xml version="1.0" encoding="UTF-8" ?>
          # <Response>
          #    <Say>Hello World</Say>
          # </Response>

          it { run_and_assert! }
        end

        context "specified" do
          # From: http://www.twilio.com/docs/api/twiml/say

          # "The 'language' attribute allows you pick a voice with a
          # specific language's accent and pronunciations."

          let(:cassette) { :say_with_language }

          def cassette_options
            super.merge(:language => language)
          end

          context 'de' do
            # Twilio currently supports German (de)

            # <?xml version="1.0" encoding="UTF-8" ?>
            # <Response>
            #    <Say language="de">Hello World</Say>
            # </Response>

            let(:language) { "de" }
            it { run_and_assert! }
          end
        end
      end

      describe "loop" do
        # From: http://www.twilio.com/docs/api/twiml/say

        # The 'loop' attribute specifies how many times you'd like the text repeated.
        # The default is once.
        # Specifying '0' will cause the <Say> verb to loop until the call is hung up.

        context "not specified" do
          # From: http://www.twilio.com/docs/api/twiml/say

          # "The default is once."

          # <?xml version="1.0" encoding="UTF-8" ?>
          # <Response>
          #    <Say>Hello World</Say>
          # </Response>

          it { run_and_assert! }
        end

        context "specified" do
          # From: http://www.twilio.com/docs/api/twiml/say

          # "The 'loop' attribute specifies how many times you'd like the text repeated."

          let(:cassette) { :say_with_loop }

          def cassette_options
            super.merge(:loop => loop)
          end

          context "'0'" do
            # From: http://www.twilio.com/docs/api/twiml/say

            # Specifying '0' will cause the <Say> verb to loop until the call is hung up.

            def setup_scenario
              stub_infinite_loop
            end

            let(:loop) { "0" }
            let(:asserted_verb_num_runs) { infinity }

            # <?xml version="1.0" encoding="UTF-8" ?>
            # <Response>
            #   <Say loop="0">Hello World</Say>
            # </Response>
            it { run_and_assert! }
          end

          context "'5'" do
            # From: http://www.twilio.com/docs/api/twiml/say

            # "The 'loop' attribute specifies how many times you'd like the text repeated."

            let(:loop) { "5" }
            let(:asserted_verb_num_runs) { 5 }

            # <?xml version="1.0" encoding="UTF-8" ?>
            # <Response>
            #   <Say loop="5">Hello World</Say>
            # </Response>

            it { run_and_assert! }
          end
        end
      end
    end
  end
end
