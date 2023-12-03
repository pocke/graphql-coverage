# frozen_string_literal: true

RSpec.describe GraphQL::Coverage do
  let(:schema) { TestSchema }

  def execute!(query)
    schema.execute(query).tap do |result|
      raise result.to_h.inspect if result['errors']
    end
  end

  before do
    GraphQL::Coverage.enable(schema)
  end

  describe '.result' do
    context "without graphql executions" do
      it 'returns result including all fields' do
        expect(GraphQL::Coverage.result).to contain_exactly(
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'foo', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'title', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'articles', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'withLazy', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Article', field: 'title', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Article', field: 'body', result_type: nil),
        )
      end
    end

    context "with missing field calls" do
      before do
        execute!(<<~GRAPHQL)
          query {
            articles {
              title
            }
          }
        GRAPHQL
      end

      it 'returns result without called fields' do
        expect(GraphQL::Coverage.result).to contain_exactly(
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'foo', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'title', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'withLazy', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Article', field: 'body', result_type: nil),
        )
      end
    end

    context 'when all fields are called' do
      before do
        execute!(<<~GRAPHQL)
          query {
            articles {
              title
            }
          }
        GRAPHQL

        execute!(<<~GRAPHQL)
          query {
            foo
            articles {
              body
            }
          }
        GRAPHQL

        execute!(<<~GRAPHQL)
          query {
            title
            withLazy
          }
        GRAPHQL
      end

      it 'returns an empty array' do
        expect(GraphQL::Coverage.result).to be_empty
      end
    end

    context 'when ignoreed_fields is specified' do
      context 'with wildcard' do
        before do
          GraphQL::Coverage.ignored_fields = [
            { owner: 'Query', field: '*' },
            { owner: '*', field: 'title' },
          ]

          execute!(<<~GRAPHQL)
            query {
              articles { body }
            }
          GRAPHQL
        end

        it 'returns an empty array' do
          expect(GraphQL::Coverage.result).to be_empty
        end
      end

      context 'with specific field' do
        before do
          GraphQL::Coverage.ignored_fields = [
            { owner: 'Query', field: 'foo' },
            { owner: 'Article', field: 'title' },
          ]

          execute!(<<~GRAPHQL)
            query {
              title
              withLazy
              articles { body }
            }
          GRAPHQL
        end

        it 'returns an empty array' do
          expect(GraphQL::Coverage.result).to be_empty
        end
      end
    end
  end

  describe '.dump' do
    before do
      execute!(<<~GRAPHQL)
        query {
          foo
        }
      GRAPHQL
    end

    include_context :mktmpdir

    it 'dumps called fields to file' do
      path = tmpdir / 'graphql-coverage.json'
      GraphQL::Coverage.dump(path)

      saved = JSON.parse(File.read(path))
      expect(saved).to eq({
        'calls' => [
          { 'owner' => 'Query', 'field' => 'foo', 'result_type' => nil },
        ],
        'schema' => 'TestSchema',
      })
    end
  end

  describe '.load' do
    context 'when files have the same shcmea' do
      include_context :mktmpdir

      before do
        content1 = {
          'calls' => [
            { 'owner' => 'Query', 'field' => 'foo', 'result_type' => nil },
          ],
          'schema' => 'TestSchema',
        }
        content2 = {
          'calls' => [
            { 'owner' => 'Query', 'field' => 'title', 'result_type' => nil },
          ],
          'schema' => 'TestSchema',
        }
        File.write(tmpdir / 'graphql-coverage-1.json', JSON.generate(content1))
        File.write(tmpdir / 'graphql-coverage-2.json', JSON.generate(content2))
      end

      it 'loads calls from files' do
        GraphQL::Coverage.load(
          tmpdir / 'graphql-coverage-1.json',
          tmpdir / 'graphql-coverage-2.json',
        )

        expect(GraphQL::Coverage::Store.current.calls).to contain_exactly(
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'foo', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'title', result_type: nil),
        )
      end
    end

    context 'when files have different schema' do
      include_context :mktmpdir

      before do
        content1 = {
          'calls' => [
            { 'owner' => 'Query', 'field' => 'foo', 'result_type' => nil },
          ],
          'schema' => 'TestSchema',
        }
        content2 = {
          'calls' => [
            { 'owner' => 'Query', 'field' => 'title', 'result_type' => nil },
          ],
          'schema' => 'String',
        }
        File.write(tmpdir / 'graphql-coverage-1.json', JSON.generate(content1))
        File.write(tmpdir / 'graphql-coverage-2.json', JSON.generate(content2))
      end

      it 'loads calls from files' do
        expect do
          GraphQL::Coverage.load(
            tmpdir / 'graphql-coverage-1.json',
            tmpdir / 'graphql-coverage-2.json',
          )
        end.to raise_error(GraphQL::Coverage::Errors::SchemaMismatch)
      end
    end
  end

  describe '.dump and .load' do
    before do
      execute!(<<~GRAPHQL)
        query {
          foo
        }
      GRAPHQL
    end

    include_context :mktmpdir

    it 'the loaded calls is the same' do
      calls = GraphQL::Coverage::Store.current.calls

      path = tmpdir / 'graphql-coverage.json'
      GraphQL::Coverage.dump(path)

      GraphQL::Coverage.reset!
      GraphQL::Coverage.load(path)

      expect(GraphQL::Coverage::Store.current.calls).to eq(calls)
    end
  end
end
