class TestSchema < GraphQL::Schema
  class FixedLazy
    def value = 42
  end

  class ArticleType < GraphQL::Schema::Object
    graphql_name 'Article'

    field :title, String, null: false
    field :body, String, null: false
  end

  class QueryType < GraphQL::Schema::Object
    graphql_name 'Query'

    field :foo, String, null: false
    def foo = "foo"

    field :title, String, null: false
    def title = "foobar"

    field :articles, [ArticleType], null: false
    def articles = [{ title: "foo", body: "bar" }, { title: "baz", body: "qux" }]

    field :with_lazy, Integer, null: false
    def with_lazy = FixedLazy.new
  end

  lazy_resolve FixedLazy, :value
  query QueryType
end
