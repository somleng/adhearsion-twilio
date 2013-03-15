require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include FakeWebHelpers

        class TestController < Adhearsion::CallController
          include Twilio::ControllerMethods

          def run
            redirect
          end
        end

        let(:call_params) do
          {
            :to => "85512456789",
            :from => "1000",
            :id => "5460696c-8cb4-11e2-99cd-1f3f1cd7995c"
          }
        end

        let(:call) do
          mock(
            "Call",
            :from => "Extension 1000 <#{call_params[:from]}@192.168.42.234>",
            :to => "#{call_params[:to]}@192.168.42.234",
            :id => call_params[:id]
          )
        end

        before do
          subject.stub(:hangup)
        end

        subject { TestController.new(call) }

        def default_config
          {
            :voice_request_url => ENV["AHN_TWILIO_VOICE_REQUEST_URL"] || "http://localhost:3000",
            :voice_request_method => ENV["AHN_TWILIO_VOICE_REQUEST_METHOD"] || "post",
            :voice_request_user => ENV["AHN_TWILIO_VOICE_REQUEST_USER"] || "user",
            :voice_request_password => ENV["AHN_TWILIO_VOICE_REQUEST_PASSWORD"] || "secret"
          }
        end

        def generate_erb(options = {})
          uri = uri_with_authentication(options.delete(:url) || default_config[:voice_request_url])
          {
            :user => uri.user,
            :password => uri.password,
            :url => uri.to_s,
            :method => default_config[:voice_request_method]
          }.merge(options)
        end

        def uri_with_authentication(url)
          uri = URI.parse(url)
          uri.user ||= default_config[:voice_request_user]
          uri.password ||= default_config[:voice_request_password]
          uri
        end

        def expect_call_status_update(options = {}, &block)
          cassette = options.delete(:cassette) || "hangup"
          VCR.use_cassette(cassette, :erb => generate_erb(options)) do
            yield
          end
        end

        describe "posting call status updates" do
          it "should post the correct parameters to the call status voice request url" do
            expect_call_status_update { subject.run }
            last_request_body["From"].should == "+#{call_params[:from]}"
            last_request_body["To"].should == "+#{call_params[:to]}"
            last_request_body["CallSid"].should == call_params[:id]
            last_request_body["CallStatus"].should == "in-progress"
          end
        end

        describe "hanging up" do
          # http://www.twilio.com/docs/api/twiml/hangup
          #
          # <?xml version="1.0" encoding="UTF-8"?>
          # <Response>
          #   <Hangup/>
          # </Response>

          it "should hang up the call" do
            subject.should_receive(:hangup)
            expect_call_status_update { subject.run }
          end
        end

        describe "redirecting" do
          # http://www.twilio.com/docs/api/twiml/redirect

          context "with no url" do
            # Note: this feature is not implemented in twilio

            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Redirect/>
            # </Response>

            it "should redirect to the default voice request url" do
              expect_call_status_update(:cassette => :redirect_no_url) { subject.run }
              last_request.path.should == URI.parse(default_config[:voice_request_url]).path
              last_request.method.downcase.should == default_config[:voice_request_method]
            end
          end

          context "with a url" do
            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Redirect>"http://localhost:3000/some_other_endpoint.xml"</Redirect>
            # </Response>

            let(:redirect_url) do
              uri_with_authentication("http://localhost:5000/some_other_endpoint.xml").to_s
            end

            it "should redirect to the specified url" do
              expect_call_status_update(:cassette => :redirect_with_url, :redirect_url => redirect_url) do
                subject.run
              end
              last_request.path.should == URI.parse(redirect_url).path
              last_request.method.downcase.should == default_config[:voice_request_method]
            end

            context "and a GET method" do
              # <?xml version="1.0" encoding="UTF-8"?>
              # <Response>
              #   <Redirect method="GET">"http://localhost:3000/some_other_endpoint.xml"</Redirect>
              # </Response>

              it "should redirect to the specified url using a 'GET' request" do
                expect_call_status_update(:cassette => :redirect_with_get_url, :redirect_url => redirect_url, :redirect_method => "get") do
                  subject.run
                end
              end
            end
          end
        end

        describe "dialing" do
          # http://www.twilio.com/docs/api/twiml/dial

          context "without specifying an action" do
            # <?xml version="1.0" encoding="UTF-8"?>
            # <Response>
            #   <Dial>+415-123-4567</Dial>
            # </Response

            it "should continue after the dial" do
              pending
            end
          end
        end
      end
    end
  end
end
