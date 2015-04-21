# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'adhearsion/twilio/version'

Gem::Specification.new do |gem|
  gem.name          = "adhearsion-twilio"
  gem.version       = Adhearsion::Twilio::VERSION
  gem.authors       = ["David Wilkie"]
  gem.email         = ["dwilkie@gmail.com"]
  gem.description   = %q{This gem provides an easy way to use Adhearsion with your existing apps built for twilio}
  gem.summary       = %q{This gem provides an easy way to use Adhearsion with your existing apps built for twilio}
  gem.homepage      = "https://github.com/dwilkie/adhearsion-twilio"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "adhearsion", "~> 2.2"
  gem.add_runtime_dependency "mail"
  gem.add_runtime_dependency "httparty"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "vcr"
  gem.add_development_dependency "webmock"
  gem.add_development_dependency "rack-test"
end
