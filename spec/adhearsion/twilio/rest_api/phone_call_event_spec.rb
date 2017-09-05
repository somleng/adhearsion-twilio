require 'spec_helper'

describe Adhearsion::Twilio::RestApi::PhoneCallEvent do

  include EnvHelpers

  describe "#notify!", :vcr => false do
    let(:stanza) { build_rayo_event_stanza }
    let(:rayo_event_namespace) { "urn:xmpp:rayo:1" }
    let(:event) { Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root, call_id, '1') }
    let(:variable_uuid) { call_id }

    subject { described_class.new(:event => event) }

    before do
      setup_scenario
    end

    def env
      {
        :ahn_twilio_rest_api_phone_call_events_url => phone_call_events_url
      }
    end

    def setup_scenario
      stub_env(env)
      do_notify!
    end

    def do_notify!
      stub_request(:post, phone_call_event_url).to_return(mocked_notify_response) if phone_call_events_url
      subject.notify!
    end

    let(:basic_auth_credentials) { "user:secret" }
    let(:phone_call_events_url) {
      "https://#{basic_auth_credentials}@somleng.example.com/api/admin/phone_calls/:phone_call_id/phone_call_events"
    }

    let(:call_id) { "3a05f57f-c664-4986-b619-44ec0a2fd60c" }

    let(:phone_call_event_url) {
      interpolate_phone_call_events_url(
        :phone_call_id => call_id
      )
    }

    let(:mocked_notify_response) {
      {
        :status => 201,
        :headers => {
          "Location" => "/api/admin/phone_calls/3abdc281-c202-4a84-9f65-5b7a97439ba8/phone_call_events/ff3e16c4-f988-4712-bca0-08d24db7a5db"
        }
      }
    }

    def interpolate_phone_call_events_url(interpolations = {})
      event_url = phone_call_events_url.dup
      interpolations.each do |interpolation, value|
        event_url.sub!(":#{interpolation}", value.to_s)
      end
      event_url.sub!("#{basic_auth_credentials}@", "")
      event_url
    end

    def parse_stanza(xml)
      Nokogiri::XML.parse(xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
    end

    def rayo_event_stanza_headers
      {"variable-uuid" => variable_uuid}
    end

    def rayo_event_stanza_children
      rayo_event_stanza_children = []
      rayo_event_stanza_headers.each do |key, value|
        rayo_event_stanza_children << {
          :element_type => :header,
          :element_attributes => [
            {
              :name => key,
              :value => value
            }
          ]
        }
      end
      rayo_event_stanza_children
    end

    def build_rayo_event_stanza
      children_xml = []
      rayo_event_stanza_children.each do |child|
        attributes = [child[:element_type]]
        child[:element_attributes].each do |element_attribute|
          element_attribute.each do |key, value|
            attributes << "#{key}=\"#{value}\""
          end
        end

        children_xml << "<#{attributes.join(' ')} />"
      end

      <<-MESSAGE
        <#{rayo_event_type} xmlns="#{rayo_event_namespace}">
          #{children_xml.join("\n")}
        </#{rayo_event_type}>
      MESSAGE
    end

    def asserted_notify_request_body
      {:type => asserted_phone_call_event_type.to_s}
    end

    def assert_request_body_param!(request_params, asserted_request_body)
      asserted_request_body.each do |asserted_key, asserted_value|
        if asserted_value.is_a?(Hash)
          expect(request_params[asserted_key.to_s]).to be_a(Hash)
          assert_request_body_param!(request_params[asserted_key.to_s], asserted_value)
        else
          expect(request_params[asserted_key.to_s]).to eq(asserted_value.to_s)
        end
      end
    end

    def assert_basic_auth!(request)
      expect(request.headers["Authorization"]).to eq("Basic #{Base64.strict_encode64(basic_auth_credentials).chomp}")
    end

    def assert_notify!
      expect(WebMock).to have_requested(
        :post, phone_call_event_url
      ).with { |request|
        assert_basic_auth!(request)
        request_params = WebMock.request_params(request)
        assert_request_body_param!(request_params, asserted_notify_request_body)
      }
      response = subject.notify_response
      expect(response).to be_present
      expect(response.code).to eq(mocked_notify_response[:status])
      expect(response.headers["Location"]).to eq(mocked_notify_response[:headers]["Location"])
    end

    context "#event => Adhearsion::Event::Ringing" do
      let(:asserted_phone_call_event_type) { :ringing }
      let(:rayo_event_type) { :ringing }
      it { assert_notify! }
    end

    context "#event => Adhearsion::Event::Answered" do
      let(:asserted_phone_call_event_type) { :answered }
      let(:rayo_event_type) { :answered }
      it { assert_notify! }
    end

    context "#event => Adhearsion::Twilio::Event::RecordingStarted" do
      let(:asserted_phone_call_event_type) { :recording_started }
      let(:recording_status_callback) { "http://somleng.example.com/recording_status_callback" }

      let(:event_params) {
        {
          "recordingStatusCallback" => recording_status_callback
        }
      }

      let(:event) { Adhearsion::Twilio::Event::RecordingStarted.new(call_id, event_params) }

      def asserted_notify_request_body
        super.merge(
          :params => {
            "recordingStatusCallback" => recording_status_callback
          }
        )
      end

      it { assert_notify! }

      describe "#fetch_details!" do
        let(:asserted_recording_uri) { "/api/2010-04-01/Accounts/54290cf9-3561-490b-b789-e692cc68afcc/Recordings/5ee7bae7-5dd6-4f2a-a19e-bb764e531492" }

        let(:mocked_fetch_details_response) {
          {
            :status => 200,
            :body => "{\"recording\":{\"uri\":\"#{asserted_recording_uri}\"}}",
            :headers => { "Content-Type" => "application/json" }
          }
        }

        def build_asserted_url_from_path(path, options = {})
          uri = URI.parse(phone_call_event_url)
          uri.host = options[:host] if options[:host]
          uri.path = path
          uri.to_s
        end

        let(:asserted_fetch_details_url) {
          build_asserted_url_from_path(mocked_notify_response[:headers]["Location"])
        }

        def do_fetch_details!
          stub_request(
            :get, asserted_fetch_details_url
          ).to_return(mocked_fetch_details_response) if asserted_fetch_details_url
          subject.fetch_details!
        end

        def setup_scenario
          super
          do_fetch_details!
        end

        context "#notify_response is available" do
          def assert_fetch_details!
            expect(WebMock).to have_requested(
              :get, asserted_fetch_details_url
            ).with { |request|
              assert_basic_auth!(request)
            }
            response = subject.fetch_details_response
            expect(response).to be_present
            expect(response.code).to eq(mocked_fetch_details_response[:status])
          end

          it { assert_fetch_details! }

          describe "#recording_uri" do
            def assert_fetch_details!
              super
              expect(subject.recording_uri).to eq(asserted_recording_uri)
            end

            it { assert_fetch_details! }
          end

          describe "#recording_url" do
            let(:asserted_recording_url) {
              build_asserted_url_from_path(asserted_recording_uri)
            }

            def assert_fetch_details!
              super
              expect(subject.recording_url).to eq(asserted_recording_url)
            end

            it { assert_fetch_details! }

            context "recording_url_host configuration is set" do
              let(:recording_url_host) { "cdn.somleng.org" }
              let(:asserted_recording_url) {
                build_asserted_url_from_path(asserted_recording_uri, :host => recording_url_host)
              }

              def env
                super.merge(
                  :ahn_twilio_recording_url_host => recording_url_host
                )
              end

              it { assert_fetch_details! }
            end
          end
        end

        context "#notify! is not setup" do
          let(:asserted_fetch_details_url) { nil }
          let(:phone_call_events_url) { nil }

          def assert_fetch_details!
            expect(subject.fetch_details_response).to eq(nil)
          end

          it { assert_fetch_details! }
        end
      end
    end

    context "#event => Adhearsion::Event::Complete" do
      let(:rayo_event_type) { :complete }
      let(:rayo_event_namespace) { "urn:xmpp:rayo:ext:1" }

      def rayo_event_stanza_headers
        {}
      end

      context "recording_complete" do
        let(:complete_namespace) { "urn:xmpp:rayo:record:complete:1" }
        let(:recording_duration) { "14440" }
        let(:recording_size) { "0" }
        let(:recording_uri) { "file:///var/lib/freeswitch/recordings/2f65c536-47f8-4fb4-9565-49677cf338c6-2.wav" }

        def rayo_event_stanza_children
          super << {
            :element_type => "recording",
            :element_attributes => [
              {
                "xmlns" => complete_namespace,
                "uri" => recording_uri,
                :duration => recording_duration,
                :size => recording_size
              }
            ]
          }
        end

        let(:asserted_phone_call_event_type) { :recording_completed }
        let(:asserted_recording_duration) { recording_duration }
        let(:asserted_recording_size) { recording_size }
        let(:asserted_recording_uri) { recording_uri }

        def asserted_notify_request_body
          super.merge(
            :params => {
              :recording_duration => asserted_recording_duration,
              :recording_size => asserted_recording_size,
              :recording_uri => asserted_recording_uri
            }
          )
        end

        it { assert_notify! }
      end

      context "fax_complete" do
        let(:complete_namespace) { "urn:xmpp:rayo:fax:complete:1" }

        def assert_notify!
          expect(WebMock).not_to have_requested(
            :post, phone_call_event_url
          )
        end

        it { assert_notify! }
      end
    end

    context "#event => Adhearsion::Event::End" do
      let(:asserted_phone_call_event_type) { :completed }
      let(:rayo_event_type) { :end }
      let(:header_sip_term_status) { "200" }
      let(:header_answer_epoch) { "1478050584" }

      let(:asserted_sip_term_status) { header_sip_term_status }
      let(:asserted_answer_epoch) { header_answer_epoch }

      def rayo_event_stanza_headers
        super.merge(
          "variable-sip_term_status" => header_sip_term_status,
          "variable-answer_epoch" => header_answer_epoch,
        )
      end

      def rayo_event_stanza_children
        super << {
          :element_type => :timeout,
          :element_attributes => [
            {
              "platform-code" => "18"
            }
          ]
        }
      end

      def asserted_notify_request_body
        super.merge(
          :params => {
            :sip_term_status => asserted_sip_term_status,
            :answer_epoch => asserted_answer_epoch
          }
        )
      end

      it { assert_notify! }
    end
  end
end
