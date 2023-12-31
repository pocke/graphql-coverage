# frozen_string_literal: true

require 'open3'

RSpec.describe 'graphql-coverage' do
  describe '#run' do
    include_context :mktmpdir

    let(:fixture_path) { File.expand_path('../fixtures/schema.rb', __dir__) }
    let(:exe) { File.expand_path('../../exe/graphql-coverage', __dir__) }

    context 'when the coverage is 100%' do
      let(:path) { tmpdir / 'result.json' }

      before do
        require_relative fixture_path
        GraphQL::Coverage.enable(TestFixtureSchema)

        TestFixtureSchema.execute('{ foo }')
        TestFixtureSchema.execute('{ bar }')

        GraphQL::Coverage.dump(path)
      end

      it 'returns 0' do
        stdout, stderr, status = Open3.capture3(exe, '-r', fixture_path, path.to_s)
        expect(status).to be_success
        expect(stdout).to eq <<~MSG
          All fields are covered
          2 / 2 fields covered (100.00%)
        MSG
        expect(stderr).to eq ""
      end
    end

    context 'when the coverage is 100% with multiple files' do
      let(:path1) { tmpdir / 'result-1.json' }
      let(:path2) { tmpdir / 'result-2.json' }

      before do
        require_relative fixture_path

        GraphQL::Coverage.enable(TestFixtureSchema)
        TestFixtureSchema.execute('{ foo }')
        GraphQL::Coverage.dump(path1)

        GraphQL::Coverage.reset!
        GraphQL::Coverage.enable(TestFixtureSchema)
        TestFixtureSchema.execute('{ bar }')
        GraphQL::Coverage.dump(path2)
      end

      it 'returns 0' do
        stdout, stderr, status = Open3.capture3(exe, '-r', fixture_path, path1.to_s, path2.to_s)
        expect(status).to be_success
        expect(stdout).to eq <<~MSG
          All fields are covered
          2 / 2 fields covered (100.00%)
        MSG
        expect(stderr).to eq ""
      end
    end

    context 'when the coverage is 100% with ignored_fields' do
      let(:path) { tmpdir / 'result.json' }

      before do
        require_relative fixture_path

        GraphQL::Coverage.enable(TestFixtureSchema)
        GraphQL::Coverage.ignored_fields = [{ type: 'Query', field: 'bar' }]
        TestFixtureSchema.execute('{ foo }')
        GraphQL::Coverage.dump(path)
      end

      it 'returns 0' do
        stdout, stderr, status = Open3.capture3(exe, '-r', fixture_path, path.to_s)
        expect(status).to be_success
        expect(stdout).to eq <<~MSG
          All fields are covered
          1 / 2 fields covered (50.00%)
          1 / 2 fields ignored (50.00%)
        MSG
        expect(stderr).to eq ""
      end
    end

    context 'when the coverage is not 100%' do
      let(:path) { tmpdir / 'result.json' }

      before do
        require_relative fixture_path
        GraphQL::Coverage.enable(TestFixtureSchema)

        TestFixtureSchema.execute('{ foo }')

        GraphQL::Coverage.dump(path)
      end

      it 'returns 1' do
        stdout, stderr, status = Open3.capture3(exe, '-r', fixture_path, path.to_s)
        expect(status).not_to be_success
        expect(stdout).to eq <<~MSG
          There are uncovered fields
          1 / 2 fields covered (50.00%)
          Missing fields:
            Query.bar
        MSG
        expect(stderr).to eq ''
      end

      context 'with --no-fail-on-uncovered' do
        it 'returns 0' do
          stdout, stderr, status = Open3.capture3(exe, '-r', fixture_path, '--no-fail-on-uncovered', path.to_s)
          expect(status).to be_success
          expect(stdout).to eq <<~MSG
            There are uncovered fields
            1 / 2 fields covered (50.00%)
            Missing fields:
              Query.bar
          MSG
          expect(stderr).to eq ''
        end
      end
    end
  end
end
