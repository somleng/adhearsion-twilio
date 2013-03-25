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

          def stub_ask_result(options = {})
            ask_result.stub(:response).and_return(options[:response] || digits)
            ask_result.stub(:status).and_return(options[:status] || :terminated)
          end

          let(:ask_result) { mock(Adhearsion::CallController::Input::Result, :response => "", :status => :timeout) }

          let(:digits) { "32" }

          before do
            subject.stub(:ask).and_return(ask_result)
          end

          def assert_ask(options = {})
            if output = options.delete(:output)
              loop = options.delete(:loop) || 1
              ask_args = Array.new(loop, output)
            else
              ask_args = [nil]
            end

            options = {
              :terminator => "#",
              :timeout => 5.seconds
            }.merge(options)

            options.delete_if { |k, v| v.nil? }
            subject.should_receive(:ask).with(*ask_args, options)
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

              def expect_call_status_update(options = {}, &block)
                super({:file_url => file_url}.merge(options), &block)
              end

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Gather>
              #     <Play>
              #       http://api.twilio.com/cowbell.mp3
              #     </Play>
              #   </Gather>
              # </Response>

              it "should ask by playing the file specified in <Play>" do
                assert_ask(:output => file_url)
                expect_call_status_update(:cassette => :gather_play) do
                  subject.run
                end
              end

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

                  context "specified" do
                    context "'0' (Differs from Twilio)" do
                      # From: http://www.twilio.com/docs/api/twiml/play

                      # "Specifying '0' will cause the the <Play> verb to loop until the call is hung up."

                      # Note this behaviour is different from Twilio
                      # If there is a <Play> with an infinite loop nested within a <Gather>
                      # adhearsion-twilio will try to play the file a maximum of 100 times

                      # <?xml version="1.0" encoding="UTF-8" ?>
                      # <Response>
                      #   <Gather>
                      #     <Play loop="0">http://api.twilio.com/cowbell.mp3</Play>
                      #   </Gather>
                      # </Response>

                      it "should repeat asking 100 times using the audio specified" do
                        assert_ask(:output => file_url, :loop => 100)
                        expect_call_status_update(:cassette => :gather_play_with_loop, :loop => "0") do
                          subject.run
                        end
                      end
                    end # context "'0'"

                    context "'5'" do
                      # From: http://www.twilio.com/docs/api/twiml/play

                      # "The 'loop' attribute specifies how many times the audio file is played."

                      # <?xml version="1.0" encoding="UTF-8" ?>
                      # <Response>
                      #   <Gather>
                      #     <Play loop="5">http://api.twilio.com/cowbell.mp3</Play>
                      #   </Gather>
                      # </Response>

                      it "should repeat asking 5 times using the audion specified" do
                        assert_ask(:output => file_url, :loop => 5)
                        expect_call_status_update(:cassette => :gather_play_with_loop, :loop => "5") do
                          subject.run
                        end
                      end
                    end # context "'5'"
                  end # context "specified"
                end # describe "'loop'"
              end # describe "Verb Attributes"

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

              before do
                stub_ask_result
              end

              context "no timeout" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # "When the caller is done entering data,
                # Twilio submits that data to the provided 'action' URL in an HTTP GET or POST request,
                # just like a web browser submits data from an HTML form."

                # Twilio will pass the following parameters in addition to the
                # standard TwiML Voice request parameters with its request to the 'action' URL:

                # | Parameter | Description                                                             |
                # | Digits    | The digits the caller pressed, excluding the finishOnKey digit if used. |

                # <?xml version="1.0" encoding="UTF-8" ?>
                # <Response>
                #   <Gather/>
                #   <Play>foo.mp3</Play>
                # </Response>

                it "should submit the data to the current URL or the provided 'action' URL" do
                  expect_call_status_update(:cassette => :gather_with_result) do
                    subject.run
                  end
                  last_request(:body)["Digits"].should == digits
                end

                # "Any TwiML verbs occuring after a <Gather> are unreachable,
                # unless the caller enters no digits."

                # <?xml version="1.0" encoding="UTF-8" ?>
                # <Response>
                #   <Gather/>
                #   <Play>foo.mp3</Play>
                # </Response>

                it "should not reach any new verbs" do
                  assert_next_verb_not_reached
                  subject.should_receive(:hangup)
                  expect_call_status_update(:cassette => :gather_with_result) do
                    subject.run
                  end
                end
              end # context "no timeout"

              context "timeout" do
                before do
                  stub_ask_result(:response => "", :status => :timeout)
                end

                # From: http://www.twilio.com/docs/api/twiml/gather

                # "If no input is received before timeout, <Gather>
                # falls through to the next verb in the TwiML document."

                # "If the 'timeout' is reached before the caller enters any digits,
                # Twilio will not make a request to the 'action' URL but instead
                # continue processing the current TwiML document with the verb immediately
                # following the <Gather>."

                # Given the following examples:

                # <?xml version="1.0" encoding="UTF-8" ?>
                # <Response>
                #   <Gather/>
                #   <Play>foo.mp3</Play>
                # </Response>

                # <?xml version="1.0" encoding="UTF-8" ?>
                # <Response>
                #   <Gather/>
                # </Response>

                it_should_behave_like "continuing to process the current TwiML", :gather
              end # context "timeout"

              context "finishOnKey pressed with no digits entered (Differs from Twilio)" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # If the caller enters the 'finishOnKey' value before entering any other digits,
                # Twilio will not make a request to the 'action' URL but instead
                # continue processing the current TwiML document with the verb immediately
                # following the <Gather>.

                # Note: It's not directly possible to achieve the Twilio behavior stated here
                # with Adhearsion out of the box. In Adhearsion when using the 'ask' command
                # and pressing the terminator key before any digits have been entered, it will
                # simply repeat the <Say> or <Play> command until the user enters digits or
                # the timeout is reached.

                # No valid test case here...

                pending "Will not implement"
              end # context "finishOnKey"

              context "not specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # "If no 'action' is provided, Twilio will by default make a
                # POST request to the current document's URL."

                before do
                  ENV['AHN_TWILIO_VOICE_REQUEST_METHOD'] = "get"
                end

                # <?xml version="1.0" encoding="UTF-8" ?>
                # <Response>
                #   <Gather/>
                #   <Play>foo.mp3</Play>
                # </Response>

                it "should make a 'POST' request to the current document's URL" do
                  expect_call_status_update(:cassette => :gather_with_result) do
                    subject.run
                  end
                  # assert there were 2 requests made
                  requests.count.should == 2
                  last_request(:url).should == default_config[:voice_request_url]
                  last_request(:method).should == :post
                end
              end # context "not specified"

              context "specified" do
                # Given the following examples:

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Gather action="http://localhost:3000/some_other_endpoint.xml"/>
                # </Response>

                # <?xml version="1.0" encoding="UTF-8"?>
                # <Response>
                #   <Gather action="../relative_endpoint.xml"/>
                # </Response>

                it_should_behave_like "a TwiML 'action' attribute", :gather_with_action
              end # context "specified"
            end # describe "'action'"

            describe "'method'" do
              # From: http://www.twilio.com/docs/api/twiml/gather

              # The 'method' attribute takes the value 'GET' or 'POST'.
              # This tells Twilio whether to request the 'action' URL via HTTP GET or POST.
              # This attribute is modeled after the HTML form 'method' attribute.
              # 'POST' is the default value.

              before do
                stub_ask_result
              end

              # Given the following examples:

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Gather action="http://localhost:3000/some_other_endpoint.xml"/>
              # </Response>

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Gather action="http://localhost:3000/some_other_endpoint.xml" method="GET"/>
              # </Response>

              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Gather action="http://localhost:3000/some_other_endpoint.xml" method="POST"/>
              # </Response>

              it_should_behave_like "a TwiML 'method' attribute", :gather_with_action
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

                it "should timeout within 5 seconds" do
                  assert_ask(:timeout => 5.seconds)
                  expect_call_status_update(:cassette => :gather) do
                    subject.run
                  end
                end
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

                  it "should timeout within 10 seconds" do
                    assert_ask(:timeout => 10.seconds)
                    expect_call_status_update(:cassette => :gather_with_timeout, :timeout => "10") do
                      subject.run
                    end
                  end
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

                it "should use '#' as the terminator" do
                  assert_ask(:terminator => "#")
                  expect_call_status_update(:cassette => :gather) do
                    subject.run
                  end
                end
              end # context "not specified"

              context "specified" do
                # From: http://www.twilio.com/docs/api/twiml/gather

                # "The 'finishOnKey' attribute lets you choose one value that submits
                # the received data when entered."

                context "''" do
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

                  it "should not use a terminator" do
                    assert_ask(:terminator => nil)
                    expect_call_status_update(:cassette => :gather_with_finish_on_key, :finish_on_key => '') do
                      subject.run
                    end
                  end
                end # context "empty string"

                context "'*'" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # | Attribute Name | Allowed Values           | Default Value        |
                  # | finishOnKey    | any digit, #, *          | #                    |

                  # "The allowed values are
                  # the digits 0-9, '#' , '*' and the empty string (set 'finishOnKey' to '')."

                  # "For example, if you set 'finishOnKey' to '*' and the user enters '1234*',
                  # Twilio will immediately stop waiting for more input when the '*' is received
                  # and will submit "Digits=1234" to the 'action' URL."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather finishOnKey="*"/>
                  # </Response>

                  it "should use '*' as the terminator" do
                    assert_ask(:terminator => "*")
                    expect_call_status_update(:cassette => :gather_with_finish_on_key, :finish_on_key => '*') do
                      subject.run
                    end
                  end
                end # context "'*'"

                context "'#'" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # | Attribute Name | Allowed Values           | Default Value        |
                  # | finishOnKey    | any digit, #, *          | #                    |

                  # "The allowed values are
                  # the digits 0-9, '#' , '*' and the empty string (set 'finishOnKey' to '')."

                  # "For example, if you set 'finishOnKey' to '*' and the user enters '1234*',
                  # Twilio will immediately stop waiting for more input when the '*' is received
                  # and will submit "Digits=1234" to the 'action' URL."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather finishOnKey="#"/>
                  # </Response>

                  it "should use '#' as the terminator" do
                    assert_ask(:terminator => "#")
                    expect_call_status_update(:cassette => :gather_with_finish_on_key, :finish_on_key => '#') do
                      subject.run
                    end
                  end
                end # context "'#'"

                context "'0'" do
                  # From: http://www.twilio.com/docs/api/twiml/gather

                  # | Attribute Name | Allowed Values           | Default Value        |
                  # | finishOnKey    | any digit, #, *          | #                    |

                  # "The allowed values are
                  # the digits 0-9, '#' , '*' and the empty string (set 'finishOnKey' to '')."

                  # "For example, if you set 'finishOnKey' to '*' and the user enters '1234*',
                  # Twilio will immediately stop waiting for more input when the '*' is received
                  # and will submit "Digits=1234" to the 'action' URL."

                  # <?xml version="1.0" encoding="UTF-8"?>
                  # <Response>
                  #   <Gather finishOnKey="#"/>
                  # </Response>

                  it "should use '0' as the terminator" do
                    assert_ask(:terminator => "0")
                    expect_call_status_update(:cassette => :gather_with_finish_on_key, :finish_on_key => '0') do
                      subject.run
                    end
                  end
                end # context "'0'"
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

                it "should not use a limit" do
                  assert_ask(:limit => nil)
                  expect_call_status_update(:cassette => :gather) do
                    subject.run
                  end
                end
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

                  it "should use a limit of 5 digits" do
                    assert_ask(:limit => 5)
                    expect_call_status_update(:cassette => :gather_with_num_digits, :num_digits => "5") do
                      subject.run
                    end
                  end
                end # context "'5'"
              end # context "specified"
            end # describe "'numDigits'"
          end # describe "Verb Attributes"
        end # describe "<Gather>"
      end # describe "mixed in to a CallController"
    end # describe "ControllerMethods"
  end # module Twilio
end # module Adhearsion
