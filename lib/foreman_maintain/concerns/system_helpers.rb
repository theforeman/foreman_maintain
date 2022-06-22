require 'rubygems'
require 'csv'
require 'find'
require 'shellwords'

module ForemanMaintain
  module Concerns
    module SystemHelpers
      include Logger
      include Concerns::Finders
      include ForemanMaintain::Concerns::OsFacts

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

      def systemd_installed?
        File.exist?('/usr/bin/systemctl')
      end

      def check_min_version(name, minimal_version)
        check_version(name) do |current_version|
          current_version >= version(minimal_version)
        end
      end

      def check_max_version(name, maximal_version)
        check_version(name) do |current_version|
          version(maximal_version) >= current_version
        end
      end

      def execute?(command, options = {})
        execute(command, options)
        $CHILD_STATUS.success?
      end

      def command_present?(command_name)
        execute?("command -v #{command_name}")
      end

      def execute_runner(command, options = {})
        command_runner = Utils::CommandRunner.new(logger, command, options)
        execution.puts '' if command_runner.interactive? && respond_to?(:execution)
        command_runner.run
        command_runner
      end

      def execute!(command, options = {})
        command_runner = execute_runner(command, options)
        if command_runner.success?
          command_runner.output
        else
          raise command_runner.execution_error
        end
      end

      def execute(command, options = {})
        execute_runner(command, options).output
      end

      def execute_with_status(command, options = {})
        command_runner = execute_runner(command, options)
        [command_runner.exit_status, command_runner.output]
      end

      def file_exists?(filename)
        File.exist?(filename)
      end

      def file_nonzero?(filename)
        File.exist?(filename) && !File.zero?(filename)
      end

      def find_package(name)
        package_manager.find_installed_package(name)
      end

      def hostname
        execute('hostname -f')
      end

      def server?
        find_package('foreman')
      end

      def packages_action(action, packages, options = {})
        options.validate_options!(:assumeyes, :yum_options)
        case action
        when :install
          package_manager.install(packages, :assumeyes => options[:assumeyes])
        when :update
          package_manager.update(packages, :assumeyes => options[:assumeyes],
                                           :yum_options => options[:yum_options])
        when :remove
          package_manager.remove(packages, :assumeyes => options[:assumeyes])
        else
          raise ArgumentError, "Unexpected action #{action} expected #{expected_actions.inspect}"
        end
      end

      def package_version(name)
        ver = if el?
                '%{VERSION}'
              elsif debian_or_ubuntu?
                '${VERSION}'
              end
        pkg = package_manager.find_installed_package(name, ver)
        version(pkg) unless pkg.nil?
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

      def shellescape(string)
        Shellwords.escape(string)
      end

      def version(value)
        Version.new(value)
      end

      def format_shell_args(options = {})
        options.map { |shell_optn, val| " #{shell_optn} #{shellescape(val)}" }.join
      end

      def find_symlinks(dir_path)
        cmd = "find '#{dir_path}' -maxdepth 1 -type l"
        result = execute(cmd).strip
        result.split(/\n/)
      end

      def directory_empty?(dir)
        Dir.entries(dir).size <= 2
      end

      def get_lv_info(dir)
        execute("findmnt -n --target #{dir} -o SOURCE,FSTYPE").split
      end

      def create_lv_snapshot(name, block_size, path)
        execute!("lvcreate -n#{name} -L#{block_size} -s #{path}")
      end

      def get_lv_path(lv_name)
        execute("lvs --noheadings -o lv_path -S lv_name=#{lv_name}").strip
      end

      def find_dir_containing_file(directory, target)
        result = nil
        Find.find(directory) do |path|
          result = File.dirname(path) if File.basename(path) == target
        end
        result
      end

      def package_manager
        ForemanMaintain.package_manager
      end

      def repository_manager
        ForemanMaintain.repository_manager
      end

      def ruby_prefix(scl = true)
        if debian_or_ubuntu?
          'ruby-'
        elsif el7? && scl
          'tfm-rubygem-'
        else
          'rubygem-'
        end
      end

      def foreman_plugin_name(plugin)
        plugin = plugin.tr('_', '-') if debian_or_ubuntu?
        ruby_prefix + plugin
      end

      def proxy_plugin_name(plugin)
        if debian_or_ubuntu?
          plugin = plugin.tr('_', '-')
          proxy_plugin_prefix = 'smart-proxy-'
        else
          proxy_plugin_prefix = 'smart_proxy_'
        end
        scl = check_min_version('foreman-proxy', '2.0')
        ruby_prefix(scl) + proxy_plugin_prefix + plugin
      end

      def hammer_plugin_name(plugin)
        plugin = plugin.tr('_', '-') if debian_or_ubuntu?
        [hammer_package, plugin].join(debian_or_ubuntu? ? '-' : '_')
      end

      def hammer_package
        hammer_prefix = if debian_or_ubuntu?
                          'hammer-cli'
                        else
                          'hammer_cli'
                        end
        ruby_prefix + hammer_prefix
      end

      private

      def check_version(name)
        current_version = package_version(name)
        if current_version
          yield current_version
        end
      end
    end
  end
end
