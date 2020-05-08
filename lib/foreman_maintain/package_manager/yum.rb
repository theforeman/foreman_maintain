module ForemanMaintain::PackageManager
  class Yum < Base
    PROTECTOR_CONFIG_FILE = '/etc/yum/pluginconf.d/foreman-protector.conf'.freeze
    PROTECTOR_WHITELIST_FILE = '/etc/yum/pluginconf.d/foreman-protector.whitelist'.freeze
    PROTECTOR_PLUGIN_FILE = '/usr/lib/yum-plugins/foreman-protector.py'.freeze

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
      !!(protector_config =~ /^\s*enabled\s*=\s*1/)
    end

    def version_locking_enabled?
      File.exist?(PROTECTOR_PLUGIN_FILE) && File.exist?(PROTECTOR_CONFIG_FILE) &&
        File.exist?(PROTECTOR_WHITELIST_FILE)
    end

    def install_version_locking(*)
      install_extras('foreman_protector/foreman-protector.py', PROTECTOR_PLUGIN_FILE)
      install_extras('foreman_protector/foreman-protector.conf', PROTECTOR_CONFIG_FILE)
      install_extras('foreman_protector/foreman-protector.whitelist', PROTECTOR_WHITELIST_FILE)
    end

    def installed?(packages)
      packages_list = [packages].flatten(1).map { |pkg| "'#{pkg}'" }.join(' ')
      sys.execute?(%(rpm -q #{packages_list}))
    end

    def find_installed_package(name)
      status, result = sys.execute_with_status(%(rpm -q '#{name}'))
      if status == 0
        result
      end
    end

    def install(packages, assumeyes: false)
      yum_action('install', packages, :assumeyes => assumeyes)
    end

    def remove(packages, assumeyes: false)
      yum_action('remove', packages, :assumeyes => assumeyes)
    end

    def update(packages = [], assumeyes: false)
      yum_action('update', packages, :assumeyes => assumeyes)
    end

    def clean_cache(assumeyes: false)
      yum_action('clean', 'all', :assumeyes => assumeyes)
    end

    def update_available?(package)
      cmd_output = yum_action('check-update -q', package, :with_status => true, :assumeyes => false)
      cmd_output[0] == 100
    end

    def files_not_owned_by_package(directory)
      find_cmd = "find #{directory} -exec /bin/sh -c 'rpm -qf {} &> /dev/null || echo {}' \\;"
      sys.execute(find_cmd).split("\n")
    end

    private

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

    def yum_action(action, packages, with_status: false, assumeyes: false)
      yum_options = []
      packages = [packages].flatten(1)
      yum_options << '-y' if assumeyes
      yum_options_s = yum_options.empty? ? '' : ' ' + yum_options.join(' ')
      packages_s = packages.empty? ? '' : ' ' + packages.join(' ')
      if with_status
        sys.execute_with_status("yum#{yum_options_s} #{action}#{packages_s}",
                                :interactive => !assumeyes)
      else
        sys.execute!("yum#{yum_options_s} #{action}#{packages_s}",
                     :interactive => !assumeyes)
      end
    end

    def install_extras(src, dest, override: false)
      extras_src = File.expand_path('../../../../extras', __FILE__)
      if override ||
         (File.directory?(dest) && !File.exist?(File.join(dest, src))) ||
         !File.exist?(dest)
        FileUtils.cp(File.join(extras_src, src), dest)
      end
    end
  end
end
