# adhearsion-twilio

Provides a simple way to use Adhearsion with your existing apps built for Twilio

[![Build Status](https://travis-ci.org/somleng/adhearsion-twilio.png)](https://travis-ci.org/somleng/adhearsion-twilio)
[![Test Coverage](https://codeclimate.com/github/somleng/adhearsion-twilio/badges/coverage.svg)](https://codeclimate.com/github/somleng/adhearsion-twilio/coverage)
[![Code Climate](https://codeclimate.com/github/somleng/adhearsion-twilio/badges/gpa.svg)](https://codeclimate.com/github/somleng/adhearsion-twilio)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'adhearsion-twilio', :git => git://github.com/somleng/adhearsion-twilio.git
```

And then execute:

```shell
$ bundle
```

## Configuration

Configure your *voice_request_url* and *status_callback_url* in `config/adhearsion.rb` or use the environment variables.
These should be the same endpoints that you point to in your Twilio configuration and should return valid TwiML.

```ruby
Adhearsion.config do |config|
  # Retrieve and execute the TwiML at this URL when a phone call is received [AHN_TWILIO_VOICE_REQUEST_URL]
  config.twilio.voice_request_url      = "http://localhost:3000/"

  # Retrieve and execute the TwiML using this http method [AHN_TWILIO_VOICE_REQUEST_METHOD]
  config.twilio.voice_request_method   = "post"

  # Make a request to this URL when a call to this phone number is completed. [AHN_TWILIO_STATUS_CALLBACK_URL]
  config.twilio.status_callback_url    = nil

  # Make a request to the status_callback_url using this method when a call to this phone number is completed. [AHN_TWILIO_STATUS_CALLBACK_METHOD]
  config.twilio.status_callback_method = nil

  # The default voice to use for a male speaker (see 'config.punchblock.default_voice' for allowed values) [AHN_TWILIO_DEFAULT_MALE_VOICE]
  config.twilio.default_male_voice     = nil

  # The default voice to use for a female speaker (see 'config.punchblock.default_voice' for allowed values) [AHN_TWILIO_DEFAULT_FEMALE_VOICE]
  config.twilio.default_female_voice   = nil
end
```

## Usage

In your controller include `Adhearsion::Twilio::ControllerMethods`, answer the call and notify your voice app like this:

```ruby
class CallController < Adhearsion::CallController
  include Adhearsion::Twilio::ControllerMethods

  def run
    notify_voice_request_url
  end
end
```

`notify_voice_request_url` will send a [Twilio Request](http://www.twilio.com/docs/api/twiml/twilio_request) using the url you configured in `voice_request_url` then execute any TwiML you respond back with.

## Documentation

Read through [the specs](https://github.com/somleng/adhearsion-twilio/tree/master/spec/adhearsion/twilio). Each spec contains TwiML examples for each Verb Attribute and Noun along with the relevant [documentation from Twilio](http://www.twilio.com/docs/api/twiml).

## Already Implemented

The following verbs have been already implemented:

* [Play](https://github.com/somleng/adhearsion-twilio/blob/master/spec/adhearsion/twilio/play_spec.rb)
* [Say](https://github.com/somleng/adhearsion-twilio/blob/master/spec/adhearsion/twilio/say_spec.rb)
* [Dial](https://github.com/somleng/adhearsion-twilio/blob/master/spec/adhearsion/twilio/dial_spec.rb)
* [Gather](https://github.com/somleng/adhearsion-twilio/blob/master/spec/adhearsion/twilio/gather_spec.rb)
* [Redirect](https://github.com/somleng/adhearsion-twilio/blob/master/spec/adhearsion/twilio/redirect_spec.rb)
* [Hangup](https://github.com/somleng/adhearsion-twilio/blob/master/spec/adhearsion/twilio/hangup_spec.rb)
* [Reject](https://github.com/somleng/adhearsion-twilio/blob/master/spec/adhearsion/twilio/reject_spec.rb)
* [Record](https://github.com/somleng/adhearsion-twilio/blob/master/spec/adhearsion/twilio/record_spec.rb)

## Todo

The following verbs are not yet fully implemented:

* SMS
* Enqueue
* Leave
* Pause

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The software is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
