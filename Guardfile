guard 'rspec', :all_after_pass => false, :all_on_start => false, :keep_failed => false, :cli => "--color --format d --tag @focus" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})         { |m| "spec/#{m[1]}_spec.rb" }
end
