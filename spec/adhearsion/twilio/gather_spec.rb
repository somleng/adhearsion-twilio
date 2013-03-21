require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include_context "twilio"

        describe "<Gather>" do
          # From: http://www.twilio.com/docs/api/twiml/gather

          # The <Gather> verb collects digits that a caller enters into
          # his or her telephone keypad. When the caller is done entering data,
          # Twilio submits that data to the provided 'action' URL in an HTTP GET or POST request,
          # just like a web browser submits data from an HTML form.

          # If no input is received before timeout, <Gather>
          # falls through to the next verb in the TwiML document.

          # You may optionally nest <Say> and <Play> verbs within a <Gather> verb
          # while waiting for input. This allows you to read menu options to the caller
          # while letting her enter a menu selection at any time.
          # After the first digit is received the audio will stop playing.

          def assert_ask(options = {})
            if output = options.delete(:output)
              loop = options.delete(:loop) || 1
              ask_args = Array.new(loop, output)
            else
              ask_args = [nil]
            end

            subject.should_receive(:ask).with(*ask_args, options.merge(:terminator => "#", :timeout => 5.seconds))
          end

          describe "Nested Verbs" do
            context "none" do
              # From: http://www.twilio.com/docs/api/twiml/gather

              # This is the simplest case for a <Gather>.
              # When Twilio executes this TwiML the application will pause for up to five seconds,
              # waiting for the caller to enter digits on her keypad.

              # The <Gather> verb supports the following attributes that modify its behavior:

              # | Attribute Name | Allowed Values           | Default Value        |
              # | timeout        | positive integer         | 5 seconds            |
              # | finishOnKey    | any digit, #, *          | #                    |

              # <?xml version="1.0" encoding="UTF-8" ?>
              # <Response>
              #   <Gather/>
              # </Response>

              it "should ask with a timeout of 5 seconds and a terminator of '#'" do
                assert_ask
                expect_call_status_update(:cassette => :gather) do
                  subject.run
                end
              end
            end # context "none"

            context "<Say>" do
              # From: http://www.twilio.com/docs/api/twiml/gather

              # "After the caller enters digits on the keypad,
              # Twilio sends them in a request to the current URL.
              # We also add a nested <Say> verb.
              # This means that input can be gathered at any time during <Say>."

              before do
                set_default_voices
              end

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Gather>
              #     <Say voice="woman", language="de">
              #       Hello World
              #     </Say>
              #   </Gather>
              # </Response>

              it "should ask using the words specified in <Say>" do
                assert_ask(:output => words, :voice => default_config[:default_female_voice])
                expect_call_status_update(:cassette => :gather_say, :language => "de", :voice => "woman") do
                  subject.run
                end
              end

              context "Verb Attributes" do
                context "'loop'" do
                  context "specified" do
                    context "'0' (Differs from Twilio)" do

                      # Note this behaviour is different from Twilio
                      # If there is a say with an infinite loop nested within a <Gather>
                      # adhearsion-twilio will try to ask for the input a maximum of 100 times

                      # <?xml version="1.0" encoding="UTF-8"?>
                      # <Response>
                      #   <Gather>
                      #     <Say loop="0">
                      #       Hello World
                      #     </Say>
                      #   </Gather>
                      # </Response>

                      it "should repeat asking 100 times using the words specified in <Say>" do
                        assert_ask(:output => words, :loop => 100, :voice => default_config[:default_male_voice])
                        expect_call_status_update(:cassette => :gather_say_with_loop, :loop => "0") do
                          subject.run
                        end
                      end
                    end # context "'0' (Differs from Twilio)"

                    context "'5'" do
                      # <?xml version="1.0" encoding="UTF-8"?>
                      # <Response>
                      #   <Gather>
                      #     <Say loop="5">
                      #       Hello World
                      #     </Say>
                      #   </Gather>
                      # </Response>

                      it "should repeat asking 5 times using the words specified in <Say>" do
                        assert_ask(:output => words, :loop => 5, :voice => default_config[:default_male_voice])
                        expect_call_status_update(:cassette => :gather_say_with_loop, :loop => "5") do
                          subject.run
                        end
                      end
                    end # context "'5'"
                  end # context "specified"
                end # context "'loop'"
              end # context "Verb Attributes"
            end # context "<Say>"

            context "<Play>" do
              # From: http://www.twilio.com/docs/api/twiml/gather

              # "After the caller enters digits on the keypad,
              # Twilio sends them in a request to the current URL.
              # We also add a nested <Play> verb.
              # This means that input can be gathered at any time during <Play>."

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Gather>
              #     <Play>
              #       http://api.twilio.com/cowbell.mp3
              #     </Play>
              #   </Gather>
              # </Response>
            end # context "<Play>"

            context "<Pause>" do
            end # context "<Pause>"
          end # content "Nested Verbs"

          describe "Verb Attributes" do
            # From: http://www.twilio.com/docs/api/twiml/gather

            # The <Gather> verb supports the following attributes that modify its behavior:

            # | Attribute Name | Allowed Values           | Default Value        |
            # | action         | relative or absolute URL | current document URL |
            # | method         | GET, POST                | POST                 |
            # | timeout        | positive integer         | 5 seconds            |
            # | finishOnKey    | any digit, #, *          | #                    |
            # | numDigits      | integer >= 1             | unlimited            |

            describe "'action'" do
              # From: http://www.twilio.com/docs/api/twiml/gather

              # The 'action' attribute takes an absolute or relative URL as a value.
              # When the caller has finished entering digits
              # Twilio will make a GET or POST request to this URL including the parameters below.
              # If no 'action' is provided, Twilio will by default make a
              # POST request to the current document's URL.

              # After making this request, Twilio will continue the current call
              # using the TwiML received in your response.
              # Keep in mind that by default Twilio will re-request the current document's URL,
              # which can lead to unwanted looping behavior if you're not careful.
              # Any TwiML verbs occuring after a <Gather> are unreachable,
              # unless the caller enters no digits.

              # If the 'timeout' is reached before the caller enters any digits,
              # or if the caller enters the 'finishOnKey' value before entering any other digits,
              # Twilio will not make a request to the 'action' URL but instead
              # continue processing the current TwiML document with the verb immediately
              # following the <Gather>.

              # Request Parameters

              # Twilio will pass the following parameters in addition to the
              # standard TwiML Voice request parameters with its request to the 'action' URL:

              # | Parameter | Description                                                             |
              # | Digits    | The digits the caller pressed, excluding the finishOnKey digit if used. |

              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # "If no 'action' is provided, Twilio will by default make a
                # POST request to the current document's URL."

                # <?xml version="1.0" encoding="UTF-8" ?>
                # <Response>
                #   <Gather/>
                # </Response>
              end # context "not specified"

              context "specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # "The 'action' attribute takes an absolute or relative URL as a value."

                context "no timeout" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # "Any TwiML verbs occuring after a <Gather> are unreachable,
                  # unless the caller enters no digits."
                end # context "no timeout"

                context "timeout" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # "If the 'timeout' is reached before the caller enters any digits,
                  # Twilio will not make a request to the 'action' URL but instead
                  # continue processing the current TwiML document with the verb immediately
                  # following the <Gather>."
                end # context "timeout"

                context "finishOnKey pressed" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # If the caller enters the 'finishOnKey' value before entering any other digits,
                  # Twilio will not make a request to the 'action' URL but instead
                  # continue processing the current TwiML document with the verb immediately
                  # following the <Gather>.
                end # context "finishOnKey"

                context "absolute url" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # "The 'action' attribute takes an absolute URL as a value."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather action="http://localhost:3000/some_other_endpoint.xml"/>
                  # </Response>
                end # context "absolute url"

                context "relative url" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # "The 'action' attribute takes a relative URL as a value."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather action="../relative_endpoint.xml"/>
                  # </Response>
                end # context "relative url"
              end # context "specified"
            end # describe "'action'"

            describe "'method'" do
              # From: http://www.twilio.com/docs/api/twiml/gather

              # The 'method' attribute takes the value 'GET' or 'POST'.
              # This tells Twilio whether to request the 'action' URL via HTTP GET or POST.
              # This attribute is modeled after the HTML form 'method' attribute.
              # 'POST' is the default value.

              context "not specified (Differs from Twilio)" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # "'POST' is the default value."

                # Note: The behaviour differs here from the behaviour or Twilio.
                # If the method is not given, it will default to
                # AHN_TWILIO_VOICE_REQUEST_METHOD or config.twilio.voice_request_method

                before do
                  ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "get"
                end

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Gather action="http://localhost:3000/some_other_endpoint.xml"/>
                # </Response>
              end # context "not specified (Differs from Twilio)"

              context "specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # This tells Twilio whether to request the 'action' URL via HTTP GET or POST.
                context "'GET'" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # "This tells Twilio whether to request the 'action' URL via HTTP GET"

                  before do
                    ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "post"
                  end

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather action="http://localhost:3000/some_other_endpoint.xml" method="GET"/>
                  # </Response>
                end # context "'GET'"

                context "'POST'" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # "This tells Twilio whether to request the 'action' URL via HTTP POST"

                  before do
                    ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "get"
                  end

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather action="http://localhost:3000/some_other_endpoint.xml" method="POST"/>
                  # </Response>
                end # context "'POST'"
              end # context "specified"
            end # describe "'method'"

            describe "'timeout'" do
              # From: http://www.twilio.com/docs/api/twiml/gather

              # The 'timeout' attribute sets the limit in seconds that Twilio
              # will wait for the caller to press another digit before moving on
              # and making a request to the 'action' URL.
              # For example, if 'timeout' is '10', Twilio will wait ten seconds
              # for the caller to press another key before submitting the previously
              # entered digits to the 'action' URL.
              # Twilio waits until completing the execution of all nested verbs
              # before beginning the timeout period.

              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # | Attribute Name | Allowed Values           | Default Value        |
                # | timeout        | positive integer         | 5 seconds            |

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Gather/>
                # </Response>
              end # context "not specified"

              context "specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # The 'timeout' attribute sets the limit in seconds that Twilio
                # will wait for the caller to press another digit before moving on
                # and making a request to the 'action' URL.

                context "'10'" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # "For example, if 'timeout' is '10', Twilio will wait ten seconds
                  # for the caller to press another key before submitting the previously
                  # entered digits to the 'action' URL."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather timeout="10"/>
                  # </Response>
                end # context "'10'"
              end # context "specified"
            end # describe "'timeout'"

            describe "'finishOnKey'" do
              # From: http://www.twilio.com/docs/api/twiml/gather

              # The 'finishOnKey' attribute lets you choose one value that submits
              # the received data when entered.
              # For example, if you set 'finishOnKey' to '#' and the user enters '1234#',
              # Twilio will immediately stop waiting for more input when the '#' is received
              # and will submit "Digits=1234" to the 'action' URL.
              # Note that the 'finishOnKey' value is not sent.
              # The allowed values are
              # the digits 0-9, '#' , '*' and the empty string (set 'finishOnKey' to '').
              # If the empty string is used, <Gather> captures all input and no key will
              # end the <Gather> when pressed.
              # In this case Twilio will submit the entered digits to the 'action' URL only
              # after the timeout has been reached.
              # The default 'finishOnKey' value is '#'. The value can only be a single character.

              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # | Attribute Name | Allowed Values           | Default Value        |
                # | finishOnKey    | any digit, #, *          | #                    |

                # "The default 'finishOnKey' value is '#'."

                # "For example, if you set 'finishOnKey' to '#' and the user enters '1234#',
                # Twilio will immediately stop waiting for more input when the '#' is received
                # and will submit "Digits=1234" to the 'action' URL."

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Gather/>
                # </Response>
              end # context "not specified"

              context "specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # "The 'finishOnKey' attribute lets you choose one value that submits
                # the received data when entered."

                context "empty string" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # "(set 'finishOnKey' to '')"

                  # "If the empty string is used, <Gather> captures all input and no key will
                  # end the <Gather> when pressed.
                  # In this case Twilio will submit the entered digits to the 'action' URL only
                  # after the timeout has been reached."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather finishOnKey=""/>
                  # </Response>
                end # context "empty string"

                context "'*'" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # | Attribute Name | Allowed Values           | Default Value        |
                  # | finishOnKey    | any digit, #, *          | #                    |

                  # "The allowed values are '*'."

                  # "For example, if you set 'finishOnKey' to '*' and the user enters '1234*',
                  # Twilio will immediately stop waiting for more input when the '*' is received
                  # and will submit "Digits=1234" to the 'action' URL."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather finishOnKey="*"/>
                  # </Response>
                end # context "'*'"
              end # context "specified"
            end # describe "'finishOnKey'"

            describe "'numDigits'" do
              # From: http://www.twilio.com/docs/api/twiml/gather

              # The 'numDigits' attribute lets you set the number of digits you are expecting,
              # and submits the data to the 'action' URL once the caller enters that number of digits.
              # For example, one might set 'numDigits' to '5' and ask the caller
              # to enter a 5 digit zip code. When the caller enters the fifth digit of '94117',
              # Twilio will immediately submit the data to the 'action' URL.

              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # | Attribute Name | Allowed Values           | Default Value        |
                # | numDigits      | integer >= 1             | unlimited            |

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Gather/>
                # </Response>
              end # context "not specified"

              context "specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # "The 'numDigits' attribute lets you set the number of digits you are expecting,
                # and submits the data to the 'action' URL once the caller enters that number of digits."

                context "'5'" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # "For example, one might set 'numDigits' to '5' and ask the caller
                  # to enter a 5 digit zip code. When the caller enters the fifth digit of '94117',
                  # Twilio will immediately submit the data to the 'action' URL."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather numDigits="5"/>
                  # </Response>
                end # context "'5'"
              end # context "specified"
            end # describe "'numDigits'"
          end # describe "Verb Attributes"
        end # describe "<Gather>"
      end # describe "mixed in to a CallController"
    end # describe "ControllerMethods"
  end # module Twilio
end # module Adhearsion
