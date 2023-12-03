# frozen_string_literal: true

require 'graphql'
require 'json'

require_relative "coverage/version"
require_relative "coverage/trace"
require_relative "coverage/store"
require_relative "coverage/call"
require_relative "coverage/errors"
require_relative "coverage/result"

module GraphQL
  module Coverage
    class << self
      attr_accessor :ignored_fields
    end

    def self.enable(schema)
      self.schema = schema
      schema.trace_with(Trace)
    end

    def self.dump(file_path)
      calls = Store.current.calls.map(&:to_h)
      content = JSON.generate({ calls: calls, schema: @schema.name })
      File.write(_ = file_path, content)
    end

    def self.load(*file_paths)
      file_paths.each do |file_path|
        content = JSON.parse(File.read(_ = file_path))
        self.schema = Object.const_get(content['schema'])

        content['calls'].each do |call_hash|
          call = Call.new(owner: call_hash['owner'], field: call_hash['field'], result_type: call_hash['result_type'])
          Store.current.append(call)
        end
      end
    end

    def self.report(output: $stdout)
      res = result
      if res.empty?
        output.puts "All fields are covered"
        true
      else
        output.puts "Missing fields:"
        res.each do |call|
          output.puts "  #{call.owner}.#{call.field}"
        end
        false
      end
    end

    def self.result
      Result.new(calls: Store.current.calls, schema: @schema, ignored_fields: ignored_fields).calculate
    end

    # @api private
    def self.reset!
      __skip__ = @schema = nil
      self.ignored_fields = []
      Store.reset!
    end

    # @api private
    private_class_method def self.schema=(schema)
      if @schema && @schema != schema
        raise Errors::SchemaMismatch.new(expected: @schema, got: schema)
      end

      @schema = schema
    end
  end
end
