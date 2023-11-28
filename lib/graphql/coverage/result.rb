# frozen_string_literal: true

module GraphQL
  module Coverage
    # @api private
    class Result
      def initialize(calls:, schema:)
        @calls = calls.uniq
        @schema = schema
      end

      def calculate
        available_fields - @calls
      end

      private

      def available_fields
        # @type var target_types: Array[singleton(GraphQL::Schema::Object)]
        target_types = _ = @schema.types.select { |name, klass| klass < GraphQL::Schema::Object && !name.start_with?('__') }.values

        target_types.flat_map do |klass|
          klass.fields.values.map do |field|
            Call.from_graphql_object(field: field, result_type: nil)
          end
        end
      end
    end
  end
end
