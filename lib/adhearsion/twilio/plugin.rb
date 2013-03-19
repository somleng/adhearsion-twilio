module Adhearsion
  module Twilio
    class Plugin < Adhearsion::Plugin
      # Actions to perform when the plugin is loaded
      #
      init :twilio do
        logger.warn "Twilio has been loaded"
      end

      # Basic configuration for the plugin
      #
      config :twilio do
        voice_request_url(
          "http://localhost:3000/",
          :desc => "Retrieve and execute the TwiML at this URL when a phone call is received"
        )

        voice_request_method(
          "post",
          :desc => "Retrieve and execute the TwiML using this http method"
        )

        voice_request_user(
          "user", :desc => "HTTP Basic Auth Username for the voice request url"
        )

        voice_request_password(
          "secret", :desc => "HTTP Basic Auth Password for the voice request url"
        )
      end

      # Defining a Rake task is easy
      # The following can be invoked with:
      #   rake plugin_demo:info
      #
      tasks do
        namespace :twilio do
          desc "Prints the PluginTemplate information"
          task :info do
            STDOUT.puts "adhearsion-twilio plugin v. #{VERSION}"
          end
        end
      end

    end
  end
end
