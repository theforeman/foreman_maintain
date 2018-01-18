require 'rubygems'
require 'csv'
require 'shellwords'

module ForemanMaintain
  module Concerns
    module SystemHelpers
      include SystemExecutable

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

      def clean_all_packages(options = {})
        options.validate_options!(:assumeyes)
        yum_options = []
        yum_options << '-y' if options[:assumeyes]
        execute!("yum #{yum_options.join(' ')} clean all", :interactive => true)
        execute!('rm -rf /var/cache/yum')
        execute!('rm -rf /var/cache/dnf')
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
    end
  end
end
