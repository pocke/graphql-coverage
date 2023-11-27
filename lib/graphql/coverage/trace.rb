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

      alias execute_field_lazy execute_field
    end
  end
end
