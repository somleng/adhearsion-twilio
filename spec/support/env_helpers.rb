module EnvHelpers
  private

  def stub_env(env)
    allow(ENV).to receive(:[]).and_call_original

    env.each do |key, value|
      normalized_key = key.to_s.upcase
      allow(ENV).to receive(:has_key?).with(normalized_key).and_return(true)
      allow(ENV).to receive(:[]).with(normalized_key).and_return(value)
      allow(ENV).to receive(:[]).with(normalized_key).and_return(value)
    end
  end
end
