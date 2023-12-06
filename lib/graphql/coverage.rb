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
      content = JSON.generate({ calls: calls, schema: @schema.name, ignored_fields: ignored_fields })
      File.write(_ = file_path, content)
    end

    def self.load(*file_paths)
      file_paths.each do |file_path|
        content = JSON.parse(File.read(_ = file_path))
        self.schema = Object.const_get(content['schema'])
        self.ignored_fields = content['ignored_fields']

        content['calls'].each do |call_hash|
          call = Call.new(type: call_hash['type'], field: call_hash['field'], result_type: call_hash['result_type'])
          Store.current.append(call)
        end
      end
    end

    def self.report(output: $stdout)
      res = result

      puts_rate = proc do
        available_size = res.available_fields.size
        covered_size = res.covered_fields.size
        ignored_size = res.ignored_fields.size

        cover_rate = sprintf("%.2f", covered_size.to_f / available_size * 100)
        ignore_rate = sprintf("%.2f", ignored_size.to_f / available_size * 100)

        output.puts "#{covered_size} / #{available_size} fields covered (#{cover_rate}%)"
        output.puts "#{ignored_size} / #{available_size} fields ignored (#{ignore_rate}%)" if 0 < ignored_size
      end

      if res.uncovered_fields.empty?
        output.puts "All fields are covered"
        puts_rate.call
        true
      else
        output.puts "There are uncovered fields"
        puts_rate.call
        output.puts "Missing fields:"
        res.uncovered_fields.each do |call|
          output.puts "  #{call.type}.#{call.field}"
        end
        false
      end
    end

    def self.report!(output: $stdout)
      report(output: output) or raise Errors::UncoveredFields
    end

    def self.result
      Result.new(calls: Store.current.calls, schema: @schema, ignored_fields: ignored_fields)
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

    reset!
  end
end
