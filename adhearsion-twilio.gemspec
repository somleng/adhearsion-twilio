lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "adhearsion/twilio/version"

Gem::Specification.new do |gem|
  gem.name          = "adhearsion-twilio"
  gem.version       = Adhearsion::Twilio::VERSION
  gem.authors       = ["David Wilkie"]
  gem.email         = ["dwilkie@gmail.com"]
  gem.description   = "This gem provides an easy way to use Adhearsion with your existing apps built for twilio"
  gem.summary       = "This gem provides an easy way to use Adhearsion with your existing apps built for twilio"
  gem.homepage      = "https://github.com/dwilkie/adhearsion-twilio"

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "adhearsion", "~> 3.0.0.rc1"
  gem.add_runtime_dependency "httparty"
  gem.add_runtime_dependency "mail"
  gem.add_runtime_dependency "somleng-twilio_http_client", "~> 0.1.1"

  gem.add_development_dependency "rack-test"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "vcr"
  gem.add_development_dependency "webmock"
  gem.add_development_dependency "codecov"
end
