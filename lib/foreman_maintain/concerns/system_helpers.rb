require 'rubygems'
require 'csv'
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

      def hostname
        execute('hostname -f')
      end

      def file_exists?(filename)
        File.exist?(filename)
      end

      def version(value)
        Version.new(value)
      end

      def install_packages(packages)
        execute!("yum install #{packages.join(' ')}", :interactive => true)
      end

      def check_min_version(name, minimal_version)
        current_version = package_version(name)
        if current_version
          return current_version >= version(minimal_version)
        end
      end

      def downstream_installation?
        execute?('rpm -q satellite') ||
          (execute('rpm -q foreman') =~ /6sat.noarch/)
      end

      def package_version(name)
        # space for extension to support non-rpm distributions
        rpm_version(name)
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
        command_runner = Utils::CommandRunner.new(logger, command, options)
        execution.puts '' if command_runner.interactive? && respond_to?(:execution)
        command_runner.run
        if command_runner.success?
          command_runner.output
        else
          raise command_runner.execution_error
        end
      end

      def execute(command, options = {})
        command_runner = Utils::CommandRunner.new(logger, command, options)
        execution.puts '' if command_runner.interactive? && respond_to?(:execution)
        command_runner.run
        command_runner.output
      end

      def shellescape(string)
        Shellwords.escape(string)
      end
    end
  end
end
