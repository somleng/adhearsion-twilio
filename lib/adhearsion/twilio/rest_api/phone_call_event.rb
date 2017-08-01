require_relative "resource"

class Adhearsion::Twilio::RestApi::PhoneCallEvent < Adhearsion::Twilio::RestApi::Resource
  EVENT_MAPPINGS = {
    Adhearsion::Event::Ringing => {
      :type => :ringing
    },
    Adhearsion::Event::Answered => {
      :type => :answered
    },
    Adhearsion::Event::End => {
      :type => :completed
    }
  }

  def notify!
    if configuration.rest_api_phone_call_events_url
      event_url = phone_call_event_url(:phone_call_id => event_details[:phone_call_id])

      request_body = event_details[:params]

      request_options = {:body => request_body}
      basic_auth, url = extract_auth(event_url)
      request_options.merge!(:basic_auth => basic_auth) if basic_auth.any?

      log(:info, "POSTING to Twilio REST API at: #{url} with options: #{request_options}")

      HTTParty.post(url, request_options).body
    end
  end

  private

  def event_details
    @event_details ||= parse_event
  end

  def event
    options[:event]
  end

  def parse_event
    event_mapping = EVENT_MAPPINGS[event.class] || {}
    headers = event.headers

    request_params = {
      :type => event_mapping[:type],
      :sip_term_status => headers["variable-sip_term_status"],
      :answer_epoch => headers["variable-answer_epoch"]
    }.delete_if { |k, v| v.nil? || v.empty? }

    {
      :phone_call_id => headers["variable-uuid"],
      :params => request_params
    }
  end

  def phone_call_event_url(interpolations = {})
    event_url = configuration.rest_api_phone_call_events_url.dup
    interpolations.each do |interpolation, value|
      event_url.sub!(":#{interpolation}", value.to_s)
    end
    event_url
  end
end
