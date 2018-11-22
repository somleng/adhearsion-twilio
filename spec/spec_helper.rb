# frozen_string_literal: true

if ENV["CI"]
  require "simplecov"
  SimpleCov.start

  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "adhearsion-twilio"

RSpec.configure do |config|
  Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = "examples.txt"
end
