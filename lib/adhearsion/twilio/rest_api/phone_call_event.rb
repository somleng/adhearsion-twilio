require_relative "resource"

class Adhearsion::Twilio::RestApi::PhoneCallEvent < Adhearsion::Twilio::RestApi::Resource
  EVENT_MAPPINGS = {
    Adhearsion::Event::Ringing => {
      :type => :ringing,
      :event_parser => Proc.new { |event| event.parse_ringing_event }
    },
    Adhearsion::Event::Answered => {
      :type => :answered,
      :event_parser => Proc.new { |event| event.parse_answered_event }
    },
    Adhearsion::Event::End => {
      :type => :completed,
      :event_parser => Proc.new { |event| event.parse_end_event }
    },
    Adhearsion::Event::Complete => {
      :event_parser => Proc.new { |event| event.parse_complete_event }
    }
  }

  def notify!
    logger.info("Notifying REST API of Phone Call Event")
    if configuration.rest_api_phone_call_events_url
      logger.info("REST API phone_call_events_url configured")
      if event_details = parse_event
        logger.info("Event parsed with details: #{event_details}")
        event_url = phone_call_event_url(:phone_call_id => event_details[:phone_call_id])

        request_body = event_details[:params]

        request_options = {:body => request_body}
        basic_auth, url = extract_auth(event_url)
        request_options.merge!(:basic_auth => basic_auth) if basic_auth.any?

        log(:info, "POSTING to Twilio REST API at: #{url} with options: #{request_options}")

        HTTParty.post(url, request_options).body
      else
        logger.info("No Event Parser for #{event}")
      end
    end
  end

  def parse_ringing_event
    build_request_options(phone_call_id_from_headers, default_request_params)
  end

  def parse_answered_event
    build_request_options(phone_call_id_from_headers, default_request_params)
  end

  def parse_end_event
    headers = event.headers
    request_params = compact_hash(
      default_request_params.merge(
        :sip_term_status => headers["variable-sip_term_status"],
        :answer_epoch => headers["variable-answer_epoch"]
      )
    )

    build_request_options(phone_call_id_from_headers, request_params)
  end

  def parse_complete_event
    if recording = event.recording
      request_params = compact_hash(
        :type => :recording_completed,
        :recording_duration => recording.duration.to_s,
        :recording_size => recording.size.to_s,
        :recording_uri => recording.uri
      )

      build_request_options(
        event.target_call_id,
        request_params
      )
    end
  end

  def event
    options[:event]
  end

  private

  def compact_hash(hash)
    hash.delete_if { |k, v| v.nil? || v.empty? }
  end

  def build_request_options(phone_call_id, request_params)
    {
      :phone_call_id => phone_call_id,
      :params => request_params
    }
  end

  def default_request_params
    {
      :type => event_mapping[:type]
    }
  end

  def phone_call_id_from_headers
    event.headers["variable-uuid"]
  end

  def parse_event
    event_mapping[:event_parser] && event_mapping[:event_parser].call(self)
  end

  def phone_call_event_url(interpolations = {})
    event_url = configuration.rest_api_phone_call_events_url.dup
    interpolations.each do |interpolation, value|
      event_url.sub!(":#{interpolation}", value.to_s)
    end
    event_url
  end

  def event_mapping
    EVENT_MAPPINGS[event.class] || {}
  end
end
