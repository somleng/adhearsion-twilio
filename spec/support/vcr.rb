require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir =  "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
end

RSpec.configure do |config|
  config.around(:vcr => false) do |example|
    VCR.turned_off { example.run }
  end
end
