# frozen_string_literal: true

module GraphQL
  module Coverage
    # rubocop:disable Naming/ConstantName
    # @api private
    Call = _ = Struct.new(:owner, :field, :result_type, keyword_init: true)
    # rubocop:enable Naming/ConstantName
    class Call
      def self.from_graphql_object(field:, result_type:)
        new(owner: field.owner.graphql_name, field: field.graphql_name, result_type: result_type)
      end
    end
  end
end
