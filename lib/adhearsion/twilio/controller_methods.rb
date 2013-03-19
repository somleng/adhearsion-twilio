module Adhearsion
  module Twilio
    module ControllerMethods
      TWILIO_CALL_STATUSES = {
        :no_answer => "no-answer",
        :answer => "completed",
        :timeout => "no-answer",
        :error => "failed",
        :in_progress => "in-progress"
      }

      ELEMENT_CONTENT_KEY = "__content__"

      private

      def notify_status(new_request_url = nil, options = {})
        @last_request_url ||= config.voice_request_url
        new_request_url ||= config.voice_request_url

        new_request_uri = URI.parse(new_request_url)
        username = new_request_uri.user || config.voice_request_user
        password = new_request_uri.password || config.voice_request_password
        new_request_uri.user = nil
        new_request_uri.password = nil

        @last_request_url = URI.join(@last_request_url, new_request_url).to_s

        method = (options.delete("method") || config.voice_request_method).downcase
        method = Adhearsion.config[:twilio].voice_request_method unless method == "get"

        status = TWILIO_CALL_STATUSES[options.delete(:status) || :in_progress]

        HTTParty.send(
          method,
          @last_request_url,
          :body => {
            :From => normalized_from,
            :To => normalized_to,
            :CallSid => call.id,
            :CallStatus => status
          }.merge(options),
          :basic_auth => {
            :username => username, :password => password
          }
        )["Response"]
      end

      def execute_twiml(response)
        with_twiml(response) do |verb, content, options, next_verb|
          case verb
          when 'Play'
            twilio_play(content, options)
          when 'Gather'
            not_yet_supported!
          when 'Redirect'
            redirect(content, options)
          when 'Hangup'
            hangup
          when 'Say'
            say(content, options)
          when 'Pause'
            not_yet_supported!
          when 'Bridge'
            not_yet_supported!
          when 'Dial'
            if twilio_dial(content, options)
              # continue
              hangup unless next_verb
            else
              break
            end
          else
            raise ArgumentError "Invalid element '#{verb}'"
          end
        end
      end

      def twilio_dial(to, options = {})
        params = {}
        params[:from] = options["callerId"] if options["callerId"]
        params[:for] = options["timeout"] if options["timeout"]

        dial_status = dial(to, params).result

        continue = true

        if options["action"]
          continue = false
          redirect(
            options["action"],
            "DialCallStatus" => TWILIO_CALL_STATUSES[dial_status],
            "method" => options["method"]
          )
        end

        continue
      end

      def twilio_play(path, options = {})
        # not yet fully implemented
        play_audio(path, :renderer => :native)
      end

      def with_twiml(raw_response, &block)
        raise(ArgumentError, "The root element must be the '<Response>' element") unless raw_response
        raw_response.each_with_index do |(verb, options), index|
          options = normalize_options(options)
          yield verb, options.delete(ELEMENT_CONTENT_KEY), options, raw_response[index + 1]
        end
      end

      def redirect(url = nil, options = {})
        execute_twiml(notify_status(url, options))
      end

      def normalize_options(options)
        options.is_a?(Hash) ? options : {ELEMENT_CONTENT_KEY => options}
      end

      def normalized_from
        normalized_destination(call.from)
      end

      def normalized_to
        normalized_destination(call.to)
      end

      def normalized_destination(raw_destination)
        "+#{Mail::Address.new(raw_destination).local}"
      end

      def config
        Adhearsion.config[:twilio]
      end

      def not_yet_supported!
        raise ArgumentError, "Not yet supported"
      end
    end
  end
end
