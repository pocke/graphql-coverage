# frozen_string_literal: true

RSpec.describe GraphQL::Coverage do
  let(:schema) do
    Class.new(GraphQL::Schema) do
      article_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Article'

        field :title, String, null: false
        field :body, String, null: false
      end

      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'

        field :foo, String, null: false
        def foo = "foo"

        field :articles, [article_type], null: false
        def articles = [{ title: "foo", body: "bar"}, { title: "baz", body: "qux"}]
      end

      query query_type
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
          GraphQL::Coverage::Call.new(owner: 'Query', field: 'articles', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Article', field: 'title', result_type: nil),
          GraphQL::Coverage::Call.new(owner: 'Article', field: 'body', result_type: nil),
        )
      end
    end

    context "with missing field calls" do
      before do
        schema.execute(<<~GRAPHQL)
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
          GraphQL::Coverage::Call.new(owner: 'Article', field: 'body', result_type: nil),
        )
      end
    end

    context 'when all fields are called' do
      before do
        schema.execute(<<~GRAPHQL)
          query {
            articles {
              title
            }
          }
        GRAPHQL

        schema.execute(<<~GRAPHQL)
          query {
            foo
            articles {
              body
            }
          }
        GRAPHQL
      end

      it 'returns an empty array' do
        expect(GraphQL::Coverage.result).to be_empty
      end
    end
  end
end
