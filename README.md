# adhearsion-twilio

Provides a simple way to use Adhearsion with your existing apps built for Twilio

[![Build Status](https://travis-ci.org/dwilkie/adhearsion-twilio.png)](https://travis-ci.org/dwilkie/adhearsion-twilio)

## Installation

Add this line to your application's Gemfile:

    gem 'adhearsion-twilio', :git => git://github.com/dwilkie/adhearsion-twilio.git

And then execute:

    $ bundle

## Configuration

Configure your *voice_request* endpoint in `config/adhearsion.rb` or use the environment variables.
This should be the same endpoint that you point to in your Twilio configuration and should return valid TwiML.

    Adhearsion.config do |config|
      # The default voice to use for a female speaker (see 'config.punchblock.default_voice' for allowed values) [AHN_TWILIO_DEFAULT_FEMALE_VOICE]
      config.twilio.default_female_voice   = nil

      # The default voice to use for a male speaker (see 'config.punchblock.default_voice' for allowed values) [AHN_TWILIO_DEFAULT_MALE_VOICE]
      config.twilio.default_male_voice     = nil

      # Retrieve and execute the TwiML using this http method [AHN_TWILIO_VOICE_REQUEST_METHOD]
      config.twilio.voice_request_method   = "post"

      # HTTP Basic Auth Password for the voice request url [AHN_TWILIO_VOICE_REQUEST_PASSWORD]
      config.twilio.voice_request_password = "secret"

      # Retrieve and execute the TwiML at this URL when a phone call is received [AHN_TWILIO_VOICE_REQUEST_URL]
      config.twilio.voice_request_url      = "http://localhost:3000"

      # HTTP Basic Auth Username for the voice request url [AHN_TWILIO_VOICE_REQUEST_USER]
      config.twilio.voice_request_user     = "user"
    end

## Usage

In your controller include `Adhearsion::Twilio::ControllerMethods`, answer the call and redirect to your server. e.g.

    class CallController < Adhearsion::CallController
      include Adhearsion::Twilio::ControllerMethods

      def run
        answer
        redirect
      end
    end

The redirect method will post to your server at `voice_request_url` then execute any Twiml you supply back

## Documentation

[Read the specification](https://github.com/dwilkie/adhearsion-twilio/blob/master/spec/adhearsion/twilio/controller_methods_spec.rb#L100)

## Already Implemented

The following verbs have been already implemented:

* Play
* Dial
    * Number
* Redirect
* Hangup

## Todo

The following verbs are not yet fully implemented:

* Dial
    * Sip
    * Client
    * Conference
    * Queue
* Say
* Gather
* Record
* SMS
* Enqueue
* Leave
* Reject
* Pause

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
