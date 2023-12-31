# frozen_string_literal: true

require "graphql/coverage"

require 'tmpdir'
require 'pathname'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end

  config.before do
    GraphQL::Coverage.reset!
  end

  Pathname(__dir__).glob('support/**/*.rb').each { |f| require f }
end
