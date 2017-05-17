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
        def major
          segments[0]
        end

        def minor
          segments[1]
        end

        def build
          segments[2]
        end
      end

      def check_min_version(name, minimal_version)
        current_version = package_version(name)
        if current_version
          return current_version >= version(minimal_version)
        end
      end

      def downstream_installation?
        execute?('rpm -q satellite') ||
          (execute('rpm -q foreman') =~ /sat.noarch/)
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

      def file_exists?(filename)
        File.exist?(filename)
      end

      def find_package(name)
        result = execute(%(rpm -q '#{name}'))
        if $CHILD_STATUS.success?
          result
        end
      end

      def hostname
        execute('hostname -f')
      end

      def server?
        find_package('foreman')
      end

      def smart_proxy?
        !server? && find_package('foreman-proxy')
      end

      def packages_action(action, packages, options = {})
        expected_actions = [:install, :update]
        unless expected_actions.include?(action)
          raise ArgumentError, "Unexpected action #{action} expected #{expected_actions.inspect}"
        end
        options.validate_options!(:assumeyes)
        yum_options = []
        yum_options << '-y' if options[:assumeyes]
        execute!("yum #{yum_options.join(' ')} #{action} #{packages.join(' ')}",
                 :interactive => true)
      end

      def clean_all_packages(options = {})
        options.validate_options!(:assumeyes)
        yum_options = []
        yum_options << '-y' if options[:assumeyes]
        execute!("yum #{yum_options.join(' ')} clean all", :interactive => true)
        execute!('rm -rf /var/cache/yum')
        execute!('rm -rf /var/cache/dnf')
      end

      def package_version(name)
        # space for extension to support non-rpm distributions
        rpm_version(name)
      end

      def parse_csv(data)
        parsed_data = CSV.parse(data)
        header = parsed_data.first
        parsed_data[1..-1].map do |row|
          Hash[*header.zip(row).flatten(1)]
        end
      end

      def parse_json(json_string)
        JSON.parse(json_string)
      rescue StandardError
        nil
      end

      def rpm_version(name)
        rpm_version = execute(%(rpm -q '#{name}' --queryformat="%{VERSION}"))
        if $CHILD_STATUS.success?
          version(rpm_version)
        end
      end

      def shellescape(string)
        Shellwords.escape(string)
      end

      def version(value)
        Version.new(value)
      end

      def format_shell_args(options = {})
        options.map { |shell_optn, val| " #{shell_optn} '#{shellescape(val)}'" }.join
      end

      def fetch_etc_hostname
        execute('hostname')
      end

      def server_ip_address
        execute("ip route get 8.8.8.8 | grep -oP '(?<=src )(\\d{1,3}.){4}'").strip
      end
    end
  end
end
