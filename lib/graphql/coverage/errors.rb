# frozen_string_literal: true

module GraphQL
  module Coverage
    module Errors
      class SchemaMismatch < StandardError
        def initialize(expected:, got:)
          super("Schema mismatch: expected #{expected}, got #{got}")
        end
      end

      class UncoveredFields < StandardError
      end
    end
  end
end
