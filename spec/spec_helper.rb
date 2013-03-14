require 'adhearsion'
require 'adhearsion-twilio'

RSpec.configure do |config|
  Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
