module Adhearsion
  module Twilio
    TwimlError = Class.new Adhearsion::Error # Represents a failure to pass valid TwiML

    TWILIO_CALL_STATUSES = {
      :no_answer => "no-answer",
      :answer => "completed",
      :timeout => "no-answer",
      :error => "failed",
      :in_progress => "in-progress"
    }

    ELEMENT_CONTENT_KEY = "__content__"
    INFINITY = 100

    module ControllerMethods
      private

      def notify_status(new_request_url = nil, options = {})
        if @last_request_url
          method = options.delete("method") || "post"
          @last_request_url = URI.join(@last_request_url, new_request_url.to_s).to_s
        else
          method = config.voice_request_method
          @last_request_url = config.voice_request_url
        end

        status = TWILIO_CALL_STATUSES[options.delete(:status) || :in_progress]

        HTTParty.send(
          method.downcase,
          @last_request_url,
          :body => {
            :From => normalized_from,
            :To => normalized_to,
            :CallSid => call.id,
            :CallStatus => status
          }.merge(options)
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
            break unless twilio_gather(node, options)
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
            break unless twilio_dial(content, options)
          else
            raise ArgumentError "Invalid element '#{verb}'"
          end
        end
        hangup
      end

      def twilio_gather(node, options = {})
        ask_params = []
        ask_options = {}

        node.children.each do |nested_verb_node|
          verb = nested_verb_node.name
          raise(
            TwimlError,
            "Nested verb '<#{verb}>' not allowed within '<#{node.name}>'"
          ) unless ["Say", "Play", "Pause"].include?(verb)

          nested_verb_options = twilio_options(nested_verb_node)
          output_count = twilio_loop(nested_verb_options, :finite => true).count
          ask_options.merge!(send("options_for_twilio_#{verb.downcase}", nested_verb_options))
          ask_params << Array.new(output_count, nested_verb_node.content)
        end

        ask_options.merge!(:timeout => (options["timeout"] || 5).to_i.seconds)

        if options["finishOnKey"]
          ask_options.merge!(
            :terminator => options["finishOnKey"]
          ) if options["finishOnKey"] =~ /^(?:\d|\*|\#)$/
        else
          ask_options.merge!(:terminator => "#")
        end

        ask_params << nil if ask_params.empty?
        result = ask(*ask_params.flatten, ask_options)
        digits = result.response

        continue = true

        unless digits.empty?
          continue = false
          redirect(options["action"], "Digits" => digits, "method" => options["method"])
        end

        continue
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

      def options_for_twilio_play(options = {})
        {}
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
        raise TwimlError, "invalid redirect url" if url && url.empty?
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
