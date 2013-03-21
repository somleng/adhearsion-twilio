require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include_context "twilio"

        describe "<Play>" do
          # From: http://www.twilio.com/docs/api/twiml/play

          # "The <Play> verb plays an audio file back to the caller.
          # Twilio retrieves the file from a URL that you provide."

          def expect_call_status_update(options = {}, &block)
            super({:file_url => file_url}.merge(options), &block)
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

                it "should play the audio once" do
                  assert_playback(:loop => 1)
                  expect_call_status_update(:cassette => :play) do
                    subject.run
                  end
                end
              end # context "not specified"

              context "specified" do
                context "'0'" do
                  # From: http://www.twilio.com/docs/api/twiml/play

                  # "Specifying '0' will cause the the <Play> verb to loop until the call is hung up."

                  before do
                    stub_infinite_loop
                  end

                  # <?xml version="1.0" encoding="UTF-8" ?>
                  # <Response>
                  #   <Play loop="0">http://api.twilio.com/cowbell.mp3</Play>
                  # </Response>

                  it "should keep playing the audio until the call is hung up" do
                    assert_playback(:loop => infinity)
                    expect_call_status_update(:cassette => :play_with_loop, :loop => "0") do
                      subject.run
                    end
                  end
                end # context "'0'"

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
                end # context "'5'"
              end # context "specified"
            end # describe "'loop'"
          end # describe "Verb Attributes"
        end # describe "<Play>"
      end # describe "mixed in to a CallController"
    end # describe "ControllerMethods"
  end # module Twilio
end # module Adhearsion
