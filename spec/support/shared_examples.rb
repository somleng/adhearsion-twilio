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
