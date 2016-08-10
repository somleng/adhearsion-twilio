shared_examples_for "a TwiML 'action' attribute" do
  def cassette_options
    super.merge(:action => action, :redirect_url => redirect_url)
  end

  def assert_requests!
    super
    expect(WebMock.requests.last.uri.to_s).to eq(redirect_url)
  end

  def assert_call_controller_assertions!
    super
    assert_next_verb_not_reached!
  end

  context "absolute url" do
    let(:action) { redirect_url }

    it { run_and_assert! }
  end # context "absolute url"

  context "relative url" do
    let(:action) { "/relative_endpoint.xml" }

    let(:redirect_url) do
      URI.join(default_config[:voice_request_url], action).to_s
    end

    it { run_and_assert! }
  end # context "relative url"
end # shared_examples_for "a TwiML 'action' attribute"

shared_examples_for "a TwiML 'method' attribute" do
  def setup_scenario
    super
    set_dummy_url_config(:voice_request, :method, config_method)
  end

  def cassette_options
    super.merge(:action => redirect_url, :redirect_url => redirect_url)
  end

  def assert_requests!
    super
    expect(WebMock.requests.last.method).to eq(asserted_method)
  end

  context "not supplied" do
    let(:cassette) { without_method_cassette }

    let(:config_method) { :get }
    let(:asserted_method) { :post }

    it { run_and_assert! }
  end # context "not supplied"

  context "supplied" do
    let(:cassette) { with_method_cassette }

    def cassette_options
      super.merge(:method_attribute => asserted_method.to_s)
    end

    context "'GET'" do
      let(:config_method) { :post }
      let(:asserted_method) { :get }

      it { run_and_assert! }
    end # context "'GET'"

    context "'POST'" do
      let(:config_method) { :get }
      let(:asserted_method) { :post }

      it { run_and_assert! }
    end # context "'POST'"
  end # context "supplied"
end # shared_examples_for "a TwiML 'method' attribute"
