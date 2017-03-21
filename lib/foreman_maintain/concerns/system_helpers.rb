require 'rubygems'
require 'csv'
require 'English'
require 'shellwords'

module ForemanMaintain
  module Concerns
    module SystemHelpers
      include Logger

      def self.included(klass)
        klass.extend(self)
      end

      # class we use for comparing the versions
      class Version < Gem::Version
      end

      class ExecutionError < StandardError
        def initialize(command, input, output)
          @command = command
          @input = input
          @output = output
          super(generate_message)
        end

        def generate_message
          ret = "Could not execute #{command}"
          ret << "with input '#{input}'" if input
          ret << ":\n #{output}" if output && !output.empty?
          ret
        end
      end

      def version(value)
        Version.new(value)
      end

      def check_min_version(name, minimal_version)
        current_version = rpm_version(name)
        if current_version
          return current_version >= version(minimal_version)
        end
      end

      def downstream_installation?
        execute?('rpm -q satellite') ||
          (execute('rpm -q foreman') =~ /6sat.noarch/)
      end

      def rpm_version(name)
        rpm_version = execute(%(rpm -q '#{name}' --queryformat="%{VERSION}"))
        if $CHILD_STATUS.success?
          version(rpm_version)
        end
      end

      def parse_csv(data)
        parsed_data = CSV.parse(data)
        header = parsed_data.first
        parsed_data[1..-1].map do |row|
          Hash[*header.zip(row).flatten(1)]
        end
      end

      def execute?(command, input = nil)
        execute(command, :stdin => input)
        $CHILD_STATUS.success?
      end

      def execute!(command, options = {})
        output = execute(command, options)
        if $CHILD_STATUS.success?
          output
        else
          raise ExecutionError.new(command, input, output)
        end
      end

      def execute(command, options = {})
        stdin, hidden_patterns = parse_execute_options(options)
        logger.debug(hide_strings("Running command #{command} with stdin #{stdin.inspect}", hidden_patterns))
        IO.popen("#{command} 2>&1", 'r+') do |f|
          if stdin
            f.puts(stdin)
            f.close_write
          end
          output = f.read
          logger.debug("output of the command:\n #{hide_strings(output, hidden_patterns)}")
          output.strip
        end
      end

      def parse_execute_options(options)
        options = options.dup
        stdin = options.delete(:stdin)
        hidden_strings = Array(options.delete(:hidden_patterns))
        raise ArgumentError, "Unexpected options: #{options.keys.inspect}" unless options.empty?
        return stdin, hidden_strings
      end

      def shellescape(string)
        Shellwords.escape(string)
      end

      def hide_strings(string, hidden_patterns)
        hidden_patterns.reduce(string) do |result, hidden_pattern|
          result.gsub(hidden_pattern, "[FILTERED]")
        end
      end
    end
  end
end
