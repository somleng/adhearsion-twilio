module SharedExamples

  def call_status_update_options
    @options ||= {
      :cassette => cassette,
      :action => redirect_url,
      :redirect_url => redirect_url
    }
  end

  shared_examples_for "a TwiML 'action' attribute" do
    context "absolute url" do
      it "should make a request to the absolute url" do
        expect_call_status_update(call_status_update_options) do
          subject.run
        end
        expect(last_request(:url)).to eq(call_status_update_options[:redirect_url])
      end
    end # context "absolute url"

    context "relative url" do
      let(:relative_url) { "../relative_endpoint.xml" }

      let(:redirect_url) do
        URI.join(default_config[:voice_request_url], relative_url).to_s
      end

      it "should make a request to the relative url" do
        expect_call_status_update(call_status_update_options) do
          subject.run
        end
        expect(last_request(:url)).to eq(call_status_update_options[:redirect_url])
      end
    end # context "relative url"
  end # shared_examples_for "a TwiML 'action' attribute"

  shared_examples_for "a TwiML 'method' attribute" do
    context "not supplied" do
      before do
        set_dummy_url_config(:voice_request, :method, :get)
      end

      it "should make a 'POST' request to the 'action' URL" do
        expect_call_status_update(call_status_update_options) do
          subject.run
        end
        expect(last_request(:method)).to eq(:post)
      end
    end # context "not supplied"

    context "supplied" do
      let(:with_method_cassette) { "#{cassette}_and_method".to_sym }

      context "'GET'" do
        before do
          set_dummy_url_config(:voice_request, :method, :post)
        end

        it "should make a 'GET' request to the 'action' URL" do
          expect_call_status_update(call_status_update_options.merge(:cassette => with_method_cassette, :method_attribute => "get")) do
            subject.run
          end
          expect(last_request(:method)).to eq(:get)
        end
      end # context "'GET'"

      context "'POST'" do
        before do
          set_dummy_url_config(:voice_request, :method, :get)
        end

        it "should make a 'POST' request to the 'action' URL" do
          expect_call_status_update(call_status_update_options.merge(:cassette => with_method_cassette, :method_attribute => "post")) do
            subject.run
          end
          expect(last_request(:method)).to eq(:post)
        end
      end # context "'POST'"
    end # context "supplied"
  end # shared_examples_for "a TwiML 'method' attribute"

  shared_examples_for "continuing to process the current TwiML" do
    it "should continue processing the TwiML after the verb" do
      cassette_with_next_verb = "#{cassette}_then_play".to_sym
      assert_next_verb_reached
      expect_call_status_update(call_status_update_options.merge(:cassette => cassette_with_next_verb)) do
        subject.run
      end
    end
  end # shared_examples_for "continuing to process the current TwiML"
end
