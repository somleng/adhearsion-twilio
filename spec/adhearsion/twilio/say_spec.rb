# frozen_string_literal: true

require "spec_helper"

RSpec.describe Adhearsion::Twilio::ControllerMethods, type: :call_controller do
  describe "<Say>" do
    # https://www.twilio.com/docs/api/twiml/say

    # The <Say> verb converts text to speech that is read back to the caller.
    # <Say> is useful for development or saying dynamic text that is difficult to pre-record.

    describe "Nouns" do
      # From: https://www.twilio.com/docs/api/twiml/say

      # The "noun" of a TwiML verb is the stuff nested within the verb
      # that's not a verb itself; it's the stuff the verb acts upon.
      # These are the nouns for <Say>:

      # | Noun        | Description                              |
      # | plain text  | The text Twilio will read to the caller. |
      # |             | Limited to 4KB (4,000 ASCII characters)  |

      # <?xml version="1.0" encoding="UTF-8" ?>
      # <Response>
      #    <Say>Hello World</Say>
      # </Response>

      it "outputs SSML" do
        controller = build_controller(allow: :say)

        VCR.use_cassette(:say, erb: generate_cassette_erb(words: "Hello World")) do
          controller.run
        end

        expect(controller).to have_received(:say) do |ssml|
          expect(ssml).to be_a(RubySpeech::SSML::Speak)
          expect(ssml.text).to eq("Hello World")
        end
      end
    end

    describe "Verb Attributes" do
      # From: https://www.twilio.com/docs/api/twiml/say

      # The <Say> verb supports the following attributes that modify its behavior:

      # | Attribute Name | Allowed Values            | Default Value |
      # | voice          | man, woman                | man           |
      # | language       | en, en-gb, es, fr, de, it | en            |
      # | loop           | integer >= 0              | 1             |

      describe "voice" do
        # From: https://www.twilio.com/docs/api/twiml/say

        # The 'voice' attribute allows you to choose
        # a male or female voice to read text back. The default value is 'man'.

        # | Attribute Name | Allowed Values | Default Value |
        # | voice          | man, woman     | man           |

        it "defaults to man" do
          # "The default value is 'man'."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Say>Hello World</Say>
          # </Response>

          controller = build_controller(allow: :say)

          VCR.use_cassette(:say, erb: generate_cassette_erb(words: "Hello World")) do
            controller.run
          end

          expect(controller).to have_received(:say) do |ssml|
            expect(fetch_ssml_attribute(ssml, :name)).to eq("man")
          end
        end

        it "sets the voice to man" do
          # From: https://www.twilio.com/docs/api/twiml/say

          # "The 'voice' attribute allows you to choose
          # a male voice to read text back."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Say voice="man">Hello World</Say>
          # </Response>

          controller = build_controller(allow: :say)

          VCR.use_cassette(:say_with_voice, erb: generate_cassette_erb(voice: "man", words: "Hello World")) do
            controller.run
          end

          expect(controller).to have_received(:say) do |ssml|
            expect(fetch_ssml_attribute(ssml, :name)).to eq("man")
          end
        end

        it "sets the voice to woman" do
          # From: https://www.twilio.com/docs/api/twiml/say

          # "The 'voice' attribute allows you to choose
          # a female voice to read text back."

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Say voice="woman">Hello World</Say>
          # </Response>

          controller = build_controller(allow: :say)

          VCR.use_cassette(:say_with_voice, erb: generate_cassette_erb(voice: "woman", words: "Hello World")) do
            controller.run
          end

          expect(controller).to have_received(:say) do |ssml|
            expect(fetch_ssml_attribute(ssml, :name)).to eq("woman")
          end
        end
      end

      describe "language" do
        # From: https://www.twilio.com/docs/api/twiml/say

        # The 'language' attribute allows you pick a voice with a
        # specific language's accent and pronunciations.
        # Twilio currently supports English with an American accent (en),
        # English with a British accent (en-gb), Spanish (es), French (fr),
        # Italian (it), and German (de).
        # The default is English with an American accent (en).

        # Note: this behaviour differs from Twilio.
        # The language option is not yet supported in adhearsion-twilio
        # so the option is ignored

        it "sets the language to en by default" do
          # From: https://www.twilio.com/docs/api/twiml/say

          # "The default is English with an American accent (en)."

          # <?xml version="1.0" encoding="UTF-8" ?>
          # <Response>
          #    <Say>Hello World</Say>
          # </Response>

          controller = build_controller(allow: :say)

          VCR.use_cassette(:say, erb: generate_cassette_erb(words: "Hello World")) do
            controller.run
          end

          expect(controller).to have_received(:say) do |ssml|
            expect(fetch_ssml_attribute(ssml, :lang)).to eq("en")
          end
        end

        it "sets the language when specifying the language attribute" do
          controller = build_controller(allow: :say)

          VCR.use_cassette(:say_with_language, erb: generate_cassette_erb(language: "pt-BR", words: "Hello World")) do
            controller.run
          end

          expect(controller).to have_received(:say) do |ssml|
            expect(fetch_ssml_attribute(ssml, :lang)).to eq("pt-BR")
          end
        end
      end

      describe "loop" do
        # From: https://www.twilio.com/docs/api/twiml/say

        # The 'loop' attribute specifies how many times you'd like the text repeated.
        # The default is once.
        # Specifying '0' will cause the <Say> verb to loop until the call is hung up.

        it "plays only once by default" do
          # From: https://www.twilio.com/docs/api/twiml/say

          # "The default is once."

          # <?xml version="1.0" encoding="UTF-8" ?>
          # <Response>
          #    <Say>Hello World</Say>
          # </Response>

          controller = build_controller(allow: :say)

          VCR.use_cassette(:say, erb: generate_cassette_erb(words: "Hello World")) do
            controller.run
          end

          expect(controller).to have_received(:say).once
        end

        it "loops until hung up if 0 is specified" do
          # From: https://www.twilio.com/docs/api/twiml/say

          # Specifying '0' will cause the <Say> verb to loop until the call is hung up.

          # <?xml version="1.0" encoding="UTF-8" ?>
          # <Response>
          #   <Say loop="0">Hello World</Say>
          # </Response>

          controller = build_controller(allow: :say)
          allow(controller).to receive(:loop).and_return(20.times)

          VCR.use_cassette(:say_with_loop, erb: generate_cassette_erb(loop: "0", words: "Hello World")) do
            controller.run
          end

          expect(controller).to have_received(:say).exactly(20).times
        end

        it "loops n times when n is specified" do
          # From: https://www.twilio.com/docs/api/twiml/say

          # "The 'loop' attribute specifies how many times you'd like the text repeated."

          # <?xml version="1.0" encoding="UTF-8" ?>
          # <Response>
          #   <Say loop="5">Hello World</Say>
          # </Response>

          controller = build_controller(allow: :say)

          VCR.use_cassette(:say_with_loop, erb: generate_cassette_erb(loop: "5", words: "Hello World")) do
            controller.run
          end

          expect(controller).to have_received(:say).exactly(5).times
        end
      end
    end
  end

  def fetch_ssml_attribute(ssml, key)
    ssml.voice.children.first.attributes.fetch(key.to_s).value
  end
end
