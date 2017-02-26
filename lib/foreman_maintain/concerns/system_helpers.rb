require 'rubygems'
require 'csv'
require 'English'

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
        execute(command, input)
        $CHILD_STATUS.success?
      end

      def execute!(command, input = nil)
        output = execute(command, input)
        if $CHILD_STATUS.success?
          output
        else
          raise ExecutionError.new(command, input, output)
        end
      end

      def execute(command, stdin = nil)
        logger.debug("Running command #{command.inspect} with stdin #{stdin.inspect}")
        IO.popen("#{command} 2>&1", 'r+') do |f|
          if stdin
            f.puts(stdin)
            f.close_write
          end
          output = f.read
          logger.debug("output of the command:\n #{output}")
          output
        end
      end
    end
  end
end
