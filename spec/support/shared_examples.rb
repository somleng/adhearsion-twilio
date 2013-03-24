shared_examples_for "a TwiML 'action' attribute" do
  context "absolute url" do
    it "should redirect to the absolute url" do
      options = {:action => redirect_url, :redirect_url => redirect_url}.merge(cassette_options)
      expect_call_status_update(options) do
        subject.run
      end
      last_request(:url).should == options[:redirect_url]
    end
  end # context "absolute url"

  context "relative url" do
    let(:relative_url) { "../relative_endpoint.xml" }

    let(:redirect_url) do
      URI.join(default_config[:voice_request_url], relative_url).to_s
    end

    it "should redirect to the relative url" do
      options = {:action => relative_url, :redirect_url => redirect_url}.merge(cassette_options)
      expect_call_status_update(options) do
        subject.run
      end
      last_request(:url).should == options[:redirect_url]
    end
  end # context "relative url"
end

shared_examples_for "continuing to process the current TwiML" do
  it "should continue processing the TwiML after the verb" do
    cassette = cassette_options.delete(:cassette)
    cassette = "#{cassette}_then_play".to_sym
    assert_next_verb_reached
    expect_call_status_update(cassette_options.merge(:cassette => cassette)) do
      subject.run
    end
  end

  context "if there's no next verb" do
    it "should hangup the call" do
      subject.should_receive(:hangup)
      expect_call_status_update(cassette_options) do
        subject.run
      end
    end
  end # context "with no next verb"
end
