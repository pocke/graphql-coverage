# frozen_string_literal: true

module GraphQL
  module Coverage
    # @api private
    class Store
      def self.current
        @current
      end

      def self.reset!
        @current = new
      end

      attr_reader :calls

      def initialize
        @calls = []
      end

      def append(call)
        @calls << call
      end

      reset!
    end
  end
end
