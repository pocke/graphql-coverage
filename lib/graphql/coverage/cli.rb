# frozen_string_literal: true

require 'optparse'

module GraphQL
  module Coverage
    class CLI
      def initialize(stdout:, stderr:)
        @stdout = stdout
        @stderr = stderr
      end

      def run(argv)
        # @type var params: params
        params = {
          'fail-on-uncovered': true,
        }

        args = OptionParser.new do |opts|
          opts.banner = 'Usage: graphql-coverage [options] [result file paths]'
          opts.on('-r', '--require PATH', 'Require a file.') do |path|
            require path
          end

          opts.on('--[no-]fail-on-uncovered', 'Fail when there are uncovered fields (default: true).')
        end.parse(argv, into: _ = params)

        Coverage.load(*args)

        ok = Coverage.report(output: stdout)
        if ok || !params[:'fail-on-uncovered']
          return 0
        else
          1
        end
      end

      private

      attr_reader :stdout, :stderr
    end
  end
end
