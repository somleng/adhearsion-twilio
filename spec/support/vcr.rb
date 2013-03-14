require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = File.dirname(__FILE__) + "/../fixtures/vcr_cassettes"
  c.hook_into :fakeweb
end
