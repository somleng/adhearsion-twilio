require 'spec_helper'

describe Adhearsion::Twilio::ControllerMethods, :type => :call_controller do
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

    let(:cassette) { :gather }
    let(:asserted_verb) { :ask }
    let(:asserted_verb_args) { [any_args] }
    let(:ask_result) { double(Adhearsion::CallController::Input::Result, :response => "", :status => :timeout) }
    let(:digits) { "32" }

    def stub_ask_result(options = {})
      allow(ask_result).to receive(:response).and_return(options[:response] || digits)
      allow(ask_result).to receive(:status).and_return(options[:status] || :terminated)
    end

    def setup_scenario
      allow(subject).to receive(:ask).and_return(ask_result)
    end

    before do
      setup_scenario
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

        it { run_and_assert! }
      end # context "none"

      context "<Say>" do
        # From: http://www.twilio.com/docs/api/twiml/gather

        # "After the caller enters digits on the keypad,
        # Twilio sends them in a request to the current URL.
        # We also add a nested <Say> verb.
        # This means that input can be gathered at any time during <Say>."

        context "Verb Attributes" do
          context "'voice''" do

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Gather>
            #     <Say voice="woman", language="de">
            #       Hello World
            #     </Say>
            #   </Gather>
            # </Response>

            let(:cassette) { :gather_say }
            let(:asserted_verb_args) { [words, hash_including(:voice => current_config[:default_female_voice])] }

            def setup_scenario
              super
              set_dummy_voices
            end

            def cassette_options
              super.merge(:language => "de", :voice => "woman")
            end

            it { run_and_assert! }
          end

          context "'loop'" do
            let(:cassette) { :gather_say_with_loop }
            let(:asserted_verb_args) { [*([words] * asserted_loop), any_args] }

            def cassette_options
              super.merge(:loop => loop)
            end

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

              let(:loop) { "0" }
              let(:asserted_loop) { 100 }

              it { run_and_assert! }
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

              let(:loop) { "5" }
              let(:asserted_loop) { 5 }

              it { run_and_assert! }
            end # context "'5'"
          end # context "'loop'"
        end # context "Verb Attributes"
      end # context "<Say>"

      context "<Play>" do
        # From: http://www.twilio.com/docs/api/twiml/gather

        # "After the caller enters digits on the keypad,
        # Twilio sends them in a request to the current URL.
        # We also add a nested <Play> verb.
        # This means that input can be gathered at any time during <Play>."

        let(:cassette) { :gather_play }

        describe "Verb Attributes" do
          # From: http://www.twilio.com/docs/api/twiml/play

          # The <Play> verb supports the following attributes that modify its behavior:

          # | Attribute Name | Allowed Values | Default Value |
          # | loop           | integer >= 0   | 1             |

          let(:asserted_verb_args) { [file_url, any_args] }

          def cassette_options
            super.merge(:file_url => file_url)
          end

          describe "none" do
            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Gather>
            #     <Play>
            #       http://api.twilio.com/cowbell.mp3
            #     </Play>
            #   </Gather>
            # </Response>

            it { run_and_assert! }
          end

          describe "'loop'" do
            # From: http://www.twilio.com/docs/api/twiml/play

            # The 'loop' attribute specifies how many times the audio file is played.
            # The default behavior is to play the audio once.
            # Specifying '0' will cause the the <Play> verb to loop until the call is hung up.

            let(:cassette) { :gather_play_with_loop }
            let(:asserted_verb_args) { [*([file_url] * asserted_loop), any_args] }

            def cassette_options
              super.merge(:loop => loop)
            end

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

                let(:loop) { "0" }
                let(:asserted_loop) { 100 }

                it { run_and_assert! }
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

                let(:loop) { "5" }
                let(:asserted_loop) { 5 }

                it { run_and_assert! }
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

        def setup_scenario
          super
          stub_ask_result
        end

        context "not specified" do
          # From: http://www.twilio.com/docs/api/twiml/gather

          # "If no 'action' is provided, Twilio will by default make a
          # POST request to the current document's URL."

          # <?xml version="1.0" encoding="UTF-8" ?>
          # <Response>
          #   <Gather/>
          #   <Play>foo.mp3</Play>
          # </Response>

          let(:cassette) { :gather_with_result }

          def setup_scenario
            super
            set_dummy_url_config(:voice_request, :method, :get)
          end

          def assert_requests!
            super
            expect(WebMock.requests.count).to eq(2)
            results_request = WebMock.requests.last
            expect(results_request.uri.to_s).to eq(current_config[:voice_request_url])
            results_params = WebMock.request_params(results_request)
            expect(results_params["Digits"]).to eq(digits)
          end

          it { run_and_assert! }
        end # context "not specified"

        context "specified" do
          # "When the caller is done entering data,
          # Twilio submits that data to the provided 'action' URL in an HTTP GET or POST request,
          # just like a web browser submits data from an HTML form."

          # Given the following examples:

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather action="http://localhost:3000/some_other_endpoint.xml"/>
          # </Response>

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather action="../relative_endpoint.xml"/>
          # </Response>

          it_should_behave_like "a TwiML 'action' attribute" do
            let(:cassette) { :gather_with_action }
          end
        end # context "specified"
      end # describe "action"

      describe "'method'" do
        # From: http://www.twilio.com/docs/api/twiml/gather

        # The 'method' attribute takes the value 'GET' or 'POST'.
        # This tells Twilio whether to request the 'action' URL via HTTP GET or POST.
        # This attribute is modeled after the HTML form 'method' attribute.
        # 'POST' is the default value.

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

        def setup_scenario
          super
          stub_ask_result
        end

        it_should_behave_like "a TwiML 'method' attribute" do
          let(:without_method_cassette) { :gather_with_action }
          let(:with_method_cassette) { :gather_with_action_and_method }
        end
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

        let(:asserted_verb_args) { [any_args, hash_including(:timeout => asserted_timeout.seconds)] }

        context "behaviour" do
          let(:asserted_verb_args) { [any_args] }
          let(:cassette) { :gather_with_result }

          context "occurs" do
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

            def setup_scenario
              super
              stub_ask_result(:response => "", :status => :timeout)
            end

            def assert_call_controller_assertions!
              super
              assert_next_verb_reached!
            end

            it { run_and_assert! }
          end # context "occurs"

          context "does not occur" do
            # "Any TwiML verbs occuring after a <Gather> are unreachable,
            # unless the caller enters no digits."

            # <?xml version="1.0" encoding="UTF-8" ?>
            # <Response>
            #   <Gather/>
            #   <Play>foo.mp3</Play>
            # </Response>

            def setup_scenario
              super
              stub_ask_result
            end

            def assert_call_controller_assertions!
              super
              assert_next_verb_not_reached!
            end

            it { run_and_assert! }
          end # context "does not occur"
        end # context "behaviour"

        context "not specified" do
          # From: http://www.twilio.com/docs/api/twiml/gather

          # | Attribute Name | Allowed Values           | Default Value        |
          # | timeout        | positive integer         | 5 seconds            |

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather/>
          # </Response>

          let(:asserted_timeout) { 5 }

          it { run_and_assert! }
        end # context "not specified"

        context "specified" do
          # From: http://www.twilio.com/docs/api/twiml/gather

          # The 'timeout' attribute sets the limit in seconds that Twilio
          # will wait for the caller to press another digit before moving on
          # and making a request to the 'action' URL.

          let(:cassette) { :gather_with_timeout }

          def cassette_options
            super.merge(:timeout => timeout)
          end

          context "'10'" do
            # From: http://www.twilio.com/docs/api/twiml/gather

            # "For example, if 'timeout' is '10', Twilio will wait ten seconds
            # for the caller to press another key before submitting the previously
            # entered digits to the 'action' URL."

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Gather timeout="10"/>
            # </Response>

            let(:timeout) { "10" }
            let(:asserted_timeout) { 10 }

            it { run_and_assert! }
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

        let(:asserted_verb_params) { hash_including(:terminator => asserted_terminator) }
        let(:asserted_verb_args) { [any_args, asserted_verb_params] }

        context "behaviour" do
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
          end # ccontext "finishOnKey pressed with no digits entered (Differs from Twilio)"
        end # context "behaviour"

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

          let(:asserted_terminator) { "#" }
          it { run_and_assert! }
        end # context "not specified"

        context "specified" do
          # From: http://www.twilio.com/docs/api/twiml/gather

          # "The 'finishOnKey' attribute lets you choose one value that submits
          # the received data when entered."

          let(:cassette) { :gather_with_finish_on_key }

          def cassette_options
            super.merge(:finish_on_key => finish_on_key)
          end

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

            let(:finish_on_key) { '' }
            let(:asserted_verb_params) { hash_excluding(:terminator) }

            it { run_and_assert! }
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

            let(:finish_on_key) { '*' }
            let(:asserted_terminator) { "*" }

            it { run_and_assert! }
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

            let(:finish_on_key) { '#' }
            let(:asserted_terminator) { "#" }

            it { run_and_assert! }
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

            let(:finish_on_key) { '0' }
            let(:asserted_terminator) { "0" }

            it { run_and_assert! }
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

        let(:asserted_verb_params) { hash_including(:limit => asserted_limit) }
        let(:asserted_verb_args) { [any_args, asserted_verb_params] }

        context "not specified" do
          # From: http://www.twilio.com/docs/api/twiml/gather

          # | Attribute Name | Allowed Values           | Default Value        |
          # | numDigits      | integer >= 1             | unlimited            |

          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Gather/>
          # </Response>

          let(:asserted_verb_params) { hash_excluding(:limit) }

          it { run_and_assert! }
        end # context "not specified"

        context "specified" do
          # From: http://www.twilio.com/docs/api/twiml/gather

          # "The 'numDigits' attribute lets you set the number of digits you are expecting,
          # and submits the data to the 'action' URL once the caller enters that number of digits."

          let(:cassette) { :gather_with_num_digits }

          def cassette_options
            super.merge(:num_digits => num_digits)
          end

          context "'5'" do
            # From: http://www.twilio.com/docs/api/twiml/gather

            # "For example, one might set 'numDigits' to '5' and ask the caller
            # to enter a 5 digit zip code. When the caller enters the fifth digit of '94117',
            # Twilio will immediately submit the data to the 'action' URL."

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Gather numDigits="5"/>
            # </Response>

            let(:num_digits) { "5" }
            let(:asserted_limit) { 5 }

            it { run_and_assert! }
          end # context "'5'"
        end # context "specified"
      end # describe "'numDigits'"
    end # describe "Verb Attributes"
  end # describe "<Gather>"
end # describe Adhearsion::Twilio::ControllerMethods
