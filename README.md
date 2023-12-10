# GraphQL::Coverage

`GraphQL::Coverage` is a gem that calculates the coverage of GraphQL queries.

## Motivation

The motivation of this gem is to enforce the coverage of GraphQL queries in testing.

In our projects, we have a rule that the test cases must cover all GraphQL fields. However, it is difficult to enforce this rule because we have no tools to check the coverage of GraphQL fields.

You may think that we can check the coverage of GraphQL fields with ordinary coverage tools such as simplecov. However, it is not enough because GraphQL fields are often defined without method definition. For example:

```ruby
# without `def id`
field :id, String, null: false
```

So I need to develop a tool that can check the coverage of GraphQL fields.

## Installation

Install the gem and add to the application's Gemfile by executing:

```
$ bundle add graphql-coverage --require false --group test
```

If bundler is not being used to manage dependencies, install the gem by executing:

```
$ gem install graphql-coverage
```

## Usage

**This gem is not designed to be used in a production environment.**

This gem is designed to be used in a test environment. Here is an example of using this gem with RSpec.

### On a single process

If your RSpec runs on a single process, add the following code to `spec_helper.rb`:

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    require 'graphql/coverage'
    # Pass a class that inherits `GraphQL::Schema`.
    GraphQL::Coverage.enable(YourSchema)
  end

  config.after(:suite) do
    GraphQL::Coverage.report!
    # You can also use `GraphQL::Coverage.report` if you just want to display the report without failure.
  end
end
```

### On multiple processes

You run RSpec on multiple processes in many cases. For example, you may use [parallel_tests](https://github.com/grosser/parallel_tests), [test-queue](https://github.com/tmm1/test-queue), or [CircleCI's parallelism](https://circleci.com/docs/parallelism-faster-jobs/).
In such cases, you need to use `GraphQL::Coverage` in a different way to aggregate coverage results.

The following code is an example of using `GraphQL::Coverage` with CircleCI's parallelism on a Rails application.

```ruby
# spec_helper.rb
RSpec.configure do |config|
  config.before(:suite) do
    # Pass a class that inherits `GraphQL::Schema`.
    GraphQL::Coverage.enable(YourSchema)
  end

  config.after(:suite) do
    # Instead of `GraphQL::Coverage.report!`, use `GraphQL::Coverage.dump` to dump the coverage result to a file.
    GraphQL::Coverage.dump(Rails.root.join("tmp/graphql-coverage-#{ENV['CIRCLE_NODE_INDEX']}.json"))
  end
end
```

After running RSpec, you can aggregate the coverage results and display the coverage with the following command:

```sh
$ graphql-coverage --require ./config/environment.rb tmp/graphql-coverage-*.json
```

You must specify `--require` (or `-r`) option to load the schema. If you use Rails, you can specify `./config/environment.rb` as the argument of `--require` option.

You can also use `--no-fail-on-uncovered` option to display the coverage without failure.

### Configuration

You can specify `ignored_fields` option to ignore some fields.

```ruby
# spec_helper.rb
RSpec.configure do |config|
  config.before(:suite) do
    GraphQL::Coverage.enable(YourSchema)
    GraphQL::Coverage.ignored_fields = [
      # GraphQL::Coverage does not complain about the coverage of `Article`'s `title` field.
      { type: 'Article', field: 'title' },
      # You can use `*` as a wildcard.
      { type: '*', field: 'id' },
    ]
  end
end
```

I recommend specifying the following configuration in most cases to ignore fields for Relay Connection.

```ruby
GraphQL::Coverage.ignored_fields = [
  { type: '*', field: 'edges' },
  { type: '*', field: 'node' },
  { type: '*', field: 'cursor' },
]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pocke/graphql-coverage.
