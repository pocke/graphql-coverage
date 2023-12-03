class TestFixtureSchema < GraphQL::Schema
  class QueryType < GraphQL::Schema::Object
    graphql_name 'Query'

    field :foo, String, null: false
    def foo = "foo"

    field :bar, String, null: false
    def bar = "foobar"
  end

  query QueryType
end
