module ForemanMaintain::PackageManager
  class Dnf < Base
    PROTECTOR_CONFIG_FILE = '/etc/dnf/plugins/foreman-protector.conf'.freeze
    PROTECTOR_WHITELIST_FILE = '/etc/dnf/plugins/foreman-protector.whitelist'.freeze

    def self.parse_envra(envra)
      # envra format: 0:foreman-1.20.1.10-1.el7sat.noarch
      parsed = envra.match(/\d*:?(?<name>.*)-[^-]+-[^-]+\.[^.]+/)
      parsed ? Hash[parsed.names.map(&:to_sym).zip(parsed.captures)].merge(:envra => envra) : nil
    end

    def lock_versions
      enable_protector
    end

    def unlock_versions
      disable_protector
    end

    def versions_locked?
      !!(protector_config =~ /^\s*enabled\s*=\s*1/) &&
        protector_whitelist_file_nonzero?
    end

    def protector_whitelist_file_nonzero?
      File.exist?(PROTECTOR_WHITELIST_FILE) &&
        !File.zero?(PROTECTOR_WHITELIST_FILE)
    end

    def version_locking_supported?
      true
    end

    def installed?(packages)
      packages_list = [packages].flatten(1).map { |pkg| "'#{pkg}'" }.join(' ')
      sys.execute?(%(rpm -q #{packages_list}))
    end

    def find_installed_package(name, queryformat = '')
      rpm_cmd = "rpm -q '#{name}'"
      unless queryformat.empty?
        rpm_cmd += " --qf '#{queryformat}'"
      end
      status, result = sys.execute_with_status(rpm_cmd, interactive: false)
      if status == 0
        result
      end
    end

    def install(packages, assumeyes: false)
      dnf_action('install', packages, assumeyes: assumeyes)
    end

    def reinstall(packages, assumeyes: false)
      dnf_action('reinstall', packages, assumeyes: assumeyes)
    end

    def remove(packages, assumeyes: false)
      dnf_action('remove', packages, assumeyes: assumeyes)
    end

    def update(packages = [], assumeyes: false, dnf_options: [])
      dnf_action('update', packages, assumeyes: assumeyes, dnf_options: dnf_options)
    end

    def check_update(packages: nil, with_status: false)
      dnf_action(
        'check-update',
        packages,
        assumeyes: true,
        valid_exit_statuses: [0, 100],
        with_status: with_status
      )
    end

    def update_available?(package)
      cmd_output = dnf_action('check-update -q', package, with_status: true, assumeyes: false)
      cmd_output[0] == 100
    end

    def files_not_owned_by_package(directory)
      find_cmd = "find #{directory} -exec /bin/sh -c 'rpm -qf {} &> /dev/null || echo {}' \\;"
      sys.execute(find_cmd).split("\n")
    end

    def list_installed_packages(queryformat = '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n')
      # The queryformat should only include valid tag(s) as per `rpm --querytags` list.
      # If any special formatting is required with querytag then it should be provided with tag i.e,
      # "--%{VENDOR}"
      # The queryformat string must end with '\n'
      sys.execute!("rpm -qa --qf '#{queryformat}'").split("\n")
    end

    def clean_cache(assumeyes: false)
      dnf_action('clean', 'metadata', :assumeyes => assumeyes)
    end

    def modules_supported?
      true
    end

    def module_enabled?(name)
      _status, result = info(name)
      result.match?(/Stream.+\[e\].+/)
    end

    def enable_module(name)
      dnf_action('module enable', name, assumeyes: true)
    end

    def switch_module(name)
      dnf_action('module switch-to', name, assumeyes: true)
    end

    def module_exists?(name)
      status, _result = info(name)
      status == 0
    end

    def info(name)
      dnf_action('module info', name, with_status: true, assumeyes: true)
    end

    private

    # rubocop:disable Metrics/LineLength, Metrics/ParameterLists
    def dnf_action(action, packages, with_status: false, assumeyes: false, dnf_options: [], valid_exit_statuses: [0])
      packages = [packages].flatten(1)

      dnf_options << '-y' if assumeyes
      dnf_options << '--disableplugin=foreman-protector'

      command = ['dnf', dnf_options.join(' '), action]

      command.push(packages.join(' ')) unless packages.empty?
      command = command.join(' ')

      if with_status
        sys.execute_with_status(
          command,
          :interactive => !assumeyes
        )
      else
        sys.execute!(
          command,
          :interactive => !assumeyes,
          :valid_exit_statuses => valid_exit_statuses
        )
      end
    end
    # rubocop:enable Metrics/LineLength, Metrics/ParameterLists

    def protector_config
      File.exist?(protector_config_file) ? File.read(protector_config_file) : ''
    end

    def protector_config_file
      PROTECTOR_CONFIG_FILE
    end

    def enable_protector
      setup_protector(true)
    end

    def disable_protector
      setup_protector(false)
    end

    def setup_protector(enabled)
      config = protector_config
      config += "\n" unless config[-1] == "\n"
      enabled_re = /^\s*enabled\s*=.*$/
      if enabled_re.match(config)
        config = config.gsub(enabled_re, "enabled = #{enabled ? '1' : '0'}")
      else
        config += "enabled = #{enabled ? '1' : '0'}\n"
      end
      File.open(protector_config_file, 'w') { |file| file.puts config }
    end
  end
end
