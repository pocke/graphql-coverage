# frozen_string_literal: true

require 'graphql/coverage/cli'

RSpec.describe GraphQL::Coverage::CLI do
  before do
    GraphQL::Coverage.reset!
  end

  describe '#run' do
    include_context :mktmpdir

    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:cli) { GraphQL::Coverage::CLI.new(stdout: stdout, stderr: stderr) }
    let(:path) { tmpdir / 'result.json' }

    context 'when the coverage is 100%' do
      before do
        require_relative '../../fixtures/schema'
        GraphQL::Coverage.enable(TestFixtureSchema)

        TestFixtureSchema.execute('{ foo }')
        TestFixtureSchema.execute('{ bar }')

        GraphQL::Coverage.dump(path)
      end

      it 'returns 0' do
        expect(cli.run([path.to_s])).to eq 0
        expect(stdout.string).to eq <<~MSG
          All fields are covered
          2 / 2 fields covered (100.00%)
        MSG
        expect(stderr.string).to be_empty
      end
    end

    context 'when the coverage is not 100%' do
      before do
        require_relative '../../fixtures/schema'
        GraphQL::Coverage.enable(TestFixtureSchema)

        TestFixtureSchema.execute('{ foo }')

        GraphQL::Coverage.dump(path)
      end

      it 'returns 1' do
        expect(cli.run([path.to_s])).to eq 1
        expect(stdout.string).to eq <<~MSG
          There are uncovered fields
          1 / 2 fields covered (50.00%)
          Missing fields:
            Query.bar
        MSG
        expect(stderr.string).to be_empty
      end

      context 'with --no-fail-on-uncovered' do
        it 'returns 0' do
          expect(cli.run([path.to_s, '--no-fail-on-uncovered'])).to eq 0
          expect(stdout.string).to eq <<~MSG
            There are uncovered fields
            1 / 2 fields covered (50.00%)
            Missing fields:
              Query.bar
          MSG
          expect(stderr.string).to be_empty
        end
      end
    end
  end
end
