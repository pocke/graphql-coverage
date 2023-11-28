# frozen_string_literal: true

RSpec.describe GraphQL::Coverage do
  let(:schema) { TestSchema }

  def execute!(query)
    schema.execute(query).tap do |result|
      raise result.to_h.inspect if result['errors']
    end
  end

  before do
    GraphQL::Coverage.reset!
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

    it 'dumps called fields to file' do
      Dir.mktmpdir('graphql-coverage') do |dir|
        path = File.join(dir, 'graphql-coverage.json')
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
  end
end
