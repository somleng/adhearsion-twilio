# adhearsion-twilio

Provides a simple way to use Adhearsion with your existing apps built for Twilio

[![Build Status](https://travis-ci.org/dwilkie/adhearsion-twilio.png)](https://travis-ci.org/dwilkie/adhearsion-twilio)

## Installation

Add this line to your application's Gemfile:

    gem 'adhearsion-twilio', :git => git://github.com/dwilkie/adhearsion-twilio.git

And then execute:

    $ bundle

## Configuration

Configure your *voice_request_url* and *status_callback_url* in `config/adhearsion.rb` or use the environment variables.
These should be the same endpoints that you point to in your Twilio configuration and should return valid TwiML.

    Adhearsion.config do |config|
      # Retrieve and execute the TwiML at this URL when a phone call is received [AHN_TWILIO_VOICE_REQUEST_URL]
      config.twilio.voice_request_url      = "http://localhost:3000/"

      # Retrieve and execute the TwiML using this http method [AHN_TWILIO_VOICE_REQUEST_METHOD]
      config.twilio.voice_request_method   = "post"

      # Make a request to this URL when a call to this phone number is completed. [AHN_TWILIO_STATUS_CALLBACK_URL]
      config.twilio.status_callback_url    = "http://localhost:3000/"

      # Make a request to the status_callback_url using this method when a call to this phone number is completed. [AHN_TWILIO_STATUS_CALLBACK_METHOD]
      config.twilio.status_callback_method = "post"

      # The default voice to use for a male speaker (see 'config.punchblock.default_voice' for allowed values) [AHN_TWILIO_DEFAULT_MALE_VOICE]
      config.twilio.default_male_voice     = nil

      # The default voice to use for a female speaker (see 'config.punchblock.default_voice' for allowed values) [AHN_TWILIO_DEFAULT_FEMALE_VOICE]
      config.twilio.default_female_voice   = nil
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

Read [the specs](https://github.com/dwilkie/adhearsion-twilio/tree/master/spec/adhearsion/twilio). Each spec contains a TwiML examples for each Verb Attribute and Noun along with the relevant documentation from Twilio.

## Already Implemented

The following verbs have been already implemented:

* Play
* Say
* Dial
    * plain text
* Gather
* Redirect
* Hangup

## Todo

The following verbs are not yet fully implemented:

* Dial
    * Number
    * Sip
    * Client
    * Conference
    * Queue
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
