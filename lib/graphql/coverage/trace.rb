# frozen_string_literal: true

module GraphQL
  module Coverage
    # @api private
    module Trace
      def execute_field(field:, query:, ast_node:, arguments:, object:)
        result = super
        # TODO: result type
        Store.current.append(Call.from_graphql_object(field: field, result_type: nil))
        result
      end

      def execute_field_lazy(field:, query:, ast_node:, arguments:, object:)
        result = super
        # TODO: result type
        Store.current.append(Call.from_graphql_object(field: field, result_type: nil))
        result
      end
    end
  end
end
