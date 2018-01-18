require 'rubygems'
require 'csv'
require 'find'
require 'shellwords'

module ForemanMaintain
  module Concerns
    module SystemHelpers
      include SystemExecutable
      include Concerns::Finders

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

      def downstream_installation?
        execute?('rpm -q satellite') ||
          (execute('rpm -q foreman') =~ /sat.noarch/)
      end

      def find_package(name)
        result = execute(%(rpm -q '#{name}'))
        if $CHILD_STATUS.success?
          result
        end
      end

      def server?
        find_package('foreman')
      end

      def version(value)
        Version.new(value)
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

      def clean_all_packages
        execute!('dnf clean all') if find_package('dnf')
        execute!('yum clean all') if find_package('yum')
      end

      def distros
        @distros ||= if redhat?
                       Utils::Distros::RedHat.new
                     elsif debian?
                       Utils::Distros::Debian.new
                     elsif fedora?
                       Utils::Distros::Fedora.new
                     end
      end

      def dpkg_version(name, queryformat = 'Version')
        dpkg_version = execute(%(dpkg-query --showformat='${#{queryformat}}' --show #{name}))
        if $CHILD_STATUS.success?
          version(dpkg_version)
        end
      end

      def package_version(name)
        if redhat?
          rpm_version(name)
        elsif debian?
          dpkg_version(name)
        end
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

      def rpm_version(name, queryformat = 'VERSION')
        rpm_version = execute(%(rpm -q '#{name}' --queryformat="%{#{queryformat}}"))
        if $CHILD_STATUS.success?
          version(rpm_version)
        end
      end

      def shellescape(string)
        Shellwords.escape(string)
      end

      def debian?
        @debian ||= eval_name.include?('debian')
      end

      def redhat?
        @redhat ||= eval_name.include?('redhat')
      end

      def fedora?
        @fedora ||= eval_name.include?('fedora')
      end

      def others?
        !debian? || !redhat? || !fedora?
      end

      def eval_name
        @name ||=
          if uname == 'linux'
            if lsb_release_present?
              extract_from_lsb_release
            else
              extract_from_release_info
            end
          else
            [uname]
          end
      end

      def extract_from_lsb_release
        execute(%(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)).to_s.downcase.split(' ')
      end

      def extract_from_release_info
        execute(
          %(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | \
              grep -v "lsb" | cut -d'/' -f3 | \
              cut -d'-' -f1 | cut -d'_' -f1)
        ).to_s.downcase.split(/\n/)
      end

      def lsb_release_present?
        file_exists?('/etc/lsb-release') && file_exists?('/etc/lsb-release.d')
      end

      def uname
        @uname ||= execute(%(uname | tr "[:upper:]" "[:lower:]"))
      end

      def format_shell_args(options = {})
        options.map { |shell_optn, val| " #{shell_optn} '#{shellescape(val)}'" }.join
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
