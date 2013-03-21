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
      INFINITY = 100

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
        method = Adhearsion.config[:twilio].voice_request_method unless method == "get" || "post"

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
        ).body
      end

      def execute_twiml(response)
        with_twiml(response) do |node, next_node|
          content = node.content
          options = twilio_options(node)
          case node.name
          when 'Play'
            twilio_play(content, options)
          when 'Gather'
            twilio_gather(node, options)
          when 'Redirect'
            redirect(content, options)
          when 'Hangup'
            hangup
          when 'Say'
            twilio_say(content, options)
          when 'Pause'
            not_yet_supported!
          when 'Bridge'
            not_yet_supported!
          when 'Dial'
            if twilio_dial(content, options)
              # continue
              hangup unless next_node
            else
              break
            end
          else
            raise ArgumentError "Invalid element '#{verb}'"
          end
        end
      end

      def twilio_gather(node, options = {})
        ask_params = []
        ask_options = {}

        node.children.each do |nested_verb_node|
          verb = nested_verb_node.name
          raise(
            ArgumentError,
            "Nested verb '<#{verb}>' not allowed within '<#{node.name}>'"
          ) unless ["Say", "Play", "Pause"].include?(verb)

          nested_verb_options = twilio_options(nested_verb_node)
          output_count = twilio_loop(nested_verb_options, :finite => true).count
          ask_options.merge!(send("options_for_twilio_#{verb.downcase}", nested_verb_options))
          ask_params << Array.new(output_count, nested_verb_node.content)
        end

        ask_params << nil if ask_params.empty?
        ask(*ask_params.flatten, ask_options.merge(:terminator => "#", :timeout => 5.seconds))
      end

      def twilio_say(words, options = {})
        params = options_for_twilio_say(options)
        twilio_loop(options).each do
          say(words, params)
        end
      end

      def options_for_twilio_say(options = {})
        params = {}
        voice = options["voice"].to_s.downcase == "woman" ? config.default_female_voice : config.default_male_voice
        params[:voice] = voice if voice
        params
      end

      def twilio_dial(to, options = {})
        params = {}
        params[:from] = options["callerId"] if options["callerId"]
        params[:for] = options["timeout"] ? options["timeout"].to_i.seconds : 30.seconds

        dial_status = dial(to, params).result

        continue = true

        if options["action"]
          continue = false
          redirect(
            options["action"],
            "DialCallStatus" => TWILIO_CALL_STATUSES[dial_status], "method" => options["method"]
          )
        end

        continue
      end

      def twilio_play(path, options = {})
        twilio_loop(options).each do
          play_audio(path, :renderer => :native)
        end
      end

      def parse_twiml(xml)
        doc = ::Nokogiri::XML(xml)
        raise doc.errors.first if doc.errors.length > 0
        raise(ArgumentError, "The root element must be the '<Response>' element") unless doc.root.name == "Response"
        doc.root.children
      end

      def with_twiml(raw_response, &block)
        doc = parse_twiml(raw_response)
        doc.each_with_index do |node, index|
          yield node, doc[index + 1]
        end
      end

      def redirect(url = nil, options = {})
        execute_twiml(notify_status(url, options))
      end

      def twilio_loop(twilio_options, options = {})
        infinite_loop = options.delete(:finite) ? INFINITY.times : loop
        twilio_options["loop"].to_s == "0" ? infinite_loop : (twilio_options["loop"] || 1).to_i.times
      end

      def twilio_options(node)
        options = {}
        node.attributes.each do |key, attribute|
          options[key] = attribute.value
        end
        options
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
