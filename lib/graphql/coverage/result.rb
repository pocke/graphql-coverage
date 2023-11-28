# frozen_string_literal: true

module GraphQL
  module Coverage
    # @api private
    class Result
      def initialize(calls:, schema:, ignored_fields:)
        @calls = calls.uniq
        @schema = schema
        @ignored_fields = ignored_fields
      end

      def calculate
        reject_ignored_fields(available_fields - @calls)
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

      def reject_ignored_fields(calls)
        calls.reject do |call|
          @ignored_fields.any? do |ignored_field|
            match_pattern?(ignored_field[:owner], call.owner) && match_pattern?(ignored_field[:field], call.field)
          end
        end
      end

      def match_pattern?(pat, str)
        if pat == '*'
          true
        else
          pat == str
        end
      end
    end
  end
end
