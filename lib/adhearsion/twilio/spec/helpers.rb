module Adhearsion
  module Twilio
    module Spec
      module Helpers
        # VCR configuration

        require 'vcr'

        VCR.configure do |c|
          c.cassette_library_dir = File.dirname(__FILE__) + "/fixtures/vcr_cassettes"
          c.hook_into :webmock
        end

        # WebMock configuration

        require 'webmock/rspec'
        require 'rack/utils'

        WebMock.disable_net_connect!

        # From: https://gist.github.com/2596158
        # Thankyou Bartosz Blimke!
        # https://twitter.com/bartoszblimke/status/198391214247124993

        module LastRequest
          def clear_requests!
            @requests = nil
          end

          def requests
            @requests ||= []
          end

          def last_request=(request_signature)
            requests << request_signature
            request_signature
          end
        end

        WebMock.extend(LastRequest)
        WebMock.after_request do |request_signature, response|
          WebMock.last_request = request_signature
        end

        RSpec.configure do |config|
          config.before do
            WebMock.clear_requests!
            allow(subject).to receive(:hangup)
            allow(subject).to receive(:answer)
            allow(subject).to receive(:reject)
            allow(subject).to receive(:sleep)
            allow(mock_call).to receive(:alive?)
            allow(mock_call).to receive(:async).and_return(mock_call)
            allow(mock_call).to receive(:register_controller)
            allow(mock_call).to receive(:duration)
            allow(mock_call).to receive(:on_end)
            set_default_config!
          end
        end

        private

        # helper methods

        def call_params
          @call_params ||= {
            :to => "85512456869",
            :from => "1000",
            :id => "5250692c-3db4-11e2-99cd-2f3f1cd7994c"
          }
        end

        def mock_call
          @mock_call ||= double(
            "Call",
            :from => "Extension 1000 <#{call_params[:from]}@192.168.42.234>",
            :to => "#{call_params[:to]}@192.168.42.234",
            :id => call_params[:id]
          )
        end

        def expect_call_status_update(options = {}, &block)
          assert_call_is_hungup unless options.delete(:assert_hangup) == false
          assert_call_is_answered unless options.delete(:assert_answered) == false
          cassette = options.delete(:cassette) || :hangup
          VCR.use_cassette(cassette, :erb => generate_erb(options)) do
            yield
          end
        end

        def assert_call_is_hungup
          expect(subject).to receive(:hangup).exactly(1).times
        end

        def assert_call_is_answered
          expect(subject).to receive(:answer).exactly(1).times
        end

        def generate_erb(options = {})
          {
            :url => current_config[:voice_request_url],
            :method => current_config[:voice_request_method],
            :status_callback_url => current_config[:status_callback_url],
            :status_callback_method => current_config[:status_callback_method]
          }.merge(options)
        end

        # Configuration

        def default_config
          {
            :voice_request_url => "http://localhost:3000/",
            :voice_request_method => :post,
            :status_callback_url => nil,
            :status_callback_method => nil,
            :default_male_voice => nil,
            :default_female_voice => nil
          }
        end

        def current_config
          current_config = {}
          default_config.each do |config, value|
            current_config[config] = ENV["AHN_TWILIO_#{config.to_s.upcase}"]
          end
          current_config
        end

        def set_default_config!
          default_config.each do |config, value|
            ENV["AHN_TWILIO_#{config.to_s.upcase}"] = value.to_s
          end
        end

        def set_dummy_url_config(url_type, url_config, value)
          ENV["AHN_TWILIO_#{url_type.to_s.upcase}_#{url_config.to_s.upcase}"] = value.to_s
        end

        def set_dummy_voices
          ENV["AHN_TWILIO_DEFAULT_MALE_VOICE"] = "default_male_voice"
          ENV["AHN_TWILIO_DEFAULT_FEMALE_VOICE"] = "default_female_voice"
        end

        # WebMock
        def requests
          requests = WebMock.requests
        end

        def first_request(attribute = nil)
          request(:first, attribute)
        end

        def last_request(attribute = nil)
          request(:last, attribute)
        end

        def request(position, attribute = nil)
          request = WebMock.requests.send(position)

          case attribute
          when :body
            Rack::Utils.parse_query(request.body)
          when :url
           request.uri.to_s
          when :method
            request.method
          else
            request
          end
        end
      end
    end
  end
end
