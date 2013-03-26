require 'spec_helper'

module Adhearsion
  module Twilio
    describe ControllerMethods do
      describe "mixed in to a CallController" do
        include_context "twilio"

        describe "posting call status updates" do
          it "should post the correct parameters to the call status voice request url" do
            expect_call_status_update { subject.run }
            assert_voice_request_params("CallStatus" => "in-progress")
          end

          context "using a url with basic auth" do
            before do
              ENV['AHN_TWILIO_VOICE_REQUEST_URL'] = "https://user:password@localhost:3000/"
            end

            it "should use http basic auth" do
              expect_call_status_update { subject.run }
              last_request.uri.user.should == "user"
              last_request.uri.password.should == "password"
            end
          end
        end
      end
    end
  end
end
