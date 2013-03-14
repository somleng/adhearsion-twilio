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
          TestController.any_instance.stub(:hangup)
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
          url = options.delete(:url) || default_config[:voice_request_url]
          uri = URI.parse(url)
          uri.user ||= default_config[:voice_request_user]
          uri.password ||= default_config[:voice_request_password]
          url = uri.to_s

          {
            :user => uri.user,
            :password => uri.password,
            :url => url,
            :method => default_config[:voice_request_method]
          }.merge(options)
        end

        describe "#redirect(url = nil, options ={})" do
          it "should post the correct parameters to the call status voice request url" do
            VCR.use_cassette("redirect", :erb => generate_erb) do
              subject.run
            end

            last_request["From"].should == "+#{call_params[:from]}"
            last_request["To"].should == "+#{call_params[:to]}"
            last_request["CallSid"].should == call_params[:id]
            last_request["CallStatus"].should == "in-progress"
          end
        end
      end
    end
  end
end
