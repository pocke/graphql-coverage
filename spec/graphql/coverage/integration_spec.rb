# frozen_string_literal: true

RSpec.describe GraphQL::Coverage do
  let(:schema) do
    Class.new(GraphQL::Schema) do
      fixed_lazy = Class.new do
        def value = 42
      end

      lazy_resolve fixed_lazy, :value

      article_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Article'

        field :title, String, null: false
        field :body, String, null: false
      end

      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'

        field :foo, String, null: false
        def foo = "foo"

        field :title, String, null: false
        def title = "foobar"

        field :articles, [article_type], null: false
        def articles = [{ title: "foo", body: "bar" }, { title: "baz", body: "qux" }]

        field :with_lazy, Integer, null: false
        define_method :with_lazy do
          fixed_lazy.new
        end
      end

      query query_type
    end
  end

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
end
