require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include_context "twilio"

        describe "<Say>" do
          # http://www.twilio.com/docs/api/twiml/say

          # The <Say> verb converts text to speech that is read back to the caller.
          # <Say> is useful for development or saying dynamic text that is difficult to pre-record.

          let(:words) { "Hello World" }

          def expect_call_status_update(options = {}, &block)
            super({:words => words}.merge(options), &block)
          end

          def assert_say(options = {})
            loop = options.delete(:loop) || 1
            options.delete_if { |k, v| v.nil? }
            subject.should_receive(:say).with(words, options).exactly(loop).times
          end

          describe "Nouns" do
            # From: http://www.twilio.com/docs/api/twiml/play

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

              it "should say the words specified" do
                assert_say
                expect_call_status_update(:cassette => :say) do
                  subject.run
                end
              end
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

              before do
                ENV["AHN_TWILIO_DEFAULT_MALE_VOICE"] = "default_male_voice"
                ENV["AHN_TWILIO_DEFAULT_MALE_VOICE"] = "default_female_voice"
              end

              shared_examples_for "a male voice" do
                it "should say the words in the voice specified in AHN_TWILIO_DEFAULT_MALE_VOICE or config.twilio.default_male_voice" do
                  assert_say(:voice => default_config[:default_male_voice])
                  expect_call_status_update(vcr_options) do
                    subject.run
                  end
                end
              end

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

                it_should_behave_like "a male voice" do
                  let(:vcr_options) { {:cassette => :say} }
                end
              end

              context "'man'" do
                # From: http://www.twilio.com/docs/api/twiml/say

                # The 'voice' attribute allows you to choose
                # a male or female voice to read text back.

                # Note: The behaviour differs here from the behaviour or Twilio.
                # If the voice attribute is 'man' it will default to
                # AHN_TWILIO_DEFAULT_MALE_VOICE or config.twilio.default_male_voice

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Say voice="man">Hello World</Say>
                # </Response>

                it_should_behave_like "a male voice" do
                  let(:vcr_options) { {:cassette => :say_with_voice, :voice => "man" } }
                end
              end

              context "'woman'" do
                # From: http://www.twilio.com/docs/api/twiml/say

                # The 'voice' attribute allows you to choose
                # a male or female voice to read text back.

                # Note: The behaviour differs here from the behaviour or Twilio.
                # If the voice attribute is 'woman' it will default to
                # AHN_TWILIO_DEFAULT_FEMALE_VOICE or config.twilio.default_female_voice

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Say voice="woman">Hello World</Say>
                # </Response>

                it "should say the words in the voice specified in AHN_TWILIO_DEFAULT_FEMALE_VOICE or config.twilio.default_female_voice" do
                  assert_say(:voice => default_config[:default_female_voice])
                  expect_call_status_update(:cassette => :say_with_voice, :voice => "woman") do
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
