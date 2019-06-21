module ForemanMaintain::PackageManager
  class Yum < Base
    VERSIONLOCK_START_CLAUSE = '## foreman-maintain - start'.freeze
    VERSIONLOCK_END_CLAUSE = '## foreman-maintain - end'.freeze
    VERSIONLOCK_CONFIG_FILE = '/etc/yum/pluginconf.d/versionlock.conf'.freeze
    VERSIONLOCK_DEFAULT_LIST_FILE = '/etc/yum/pluginconf.d/versionlock.list'.freeze

    def self.parse_envra(envra)
      # envra format: 0:foreman-1.20.1.10-1.el7sat.noarch
      parsed = envra.match(/\d*:?(?<name>.*)-[^-]+-[^-]+\.[^.]+/)
      parsed ? Hash[parsed.names.zip(parsed.captures)].merge(:envra => envra) : nil
    end

    def foreman_related_packages
      query = "repoquery -a --qf='%{envra} %{repo.id}' --search foreman-installer |head -n1"
      foreman_repo = sys.execute(query).split[1]
      query_installed = "repoquery -a --qf='%{envra}' --repoid='#{foreman_repo}'"
      sys.execute(query_installed). split("\n").map do |pkg|
        self.class.parse_envra(pkg)
      end
    end

    def version_locking_packages
      %w[yum-utils yum-plugin-versionlock]
    end

    def lock_versions(package_list)
      unlock_versions
      File.open(versionlock_file, 'a') do |f|
        f.puts VERSIONLOCK_START_CLAUSE
        f.puts '# The following packages are locked by foreman-maintain. Do not modify!'
        package_list.each { |package| f.puts "#{package[:envra]}.*" }
        f.puts '# End of list of packages locked by foreman-maintain'
        f.puts VERSIONLOCK_END_CLAUSE
      end
    end

    def unlock_versions
      lock_file = versionlock_file
      content = File.read(lock_file)
      content = content.gsub(/#{VERSIONLOCK_START_CLAUSE}.*#{VERSIONLOCK_END_CLAUSE}\n/m, '')
      File.open(lock_file, 'w') { |f| f.write content }
    end

    def versions_locked?
      lock_file = versionlock_file
      return false if lock_file.nil?
      content = File.read(lock_file)
      !!content.match(/#{VERSIONLOCK_START_CLAUSE}.*#{VERSIONLOCK_END_CLAUSE}\n/m)
    end

    def version_locking_enabled?
      installed?(version_locking_packages) && versionlock_config =~ /^\s*enabled\s+=\s+1/ \
        && File.exist?(versionlock_file)
    end

    # make sure the version locking tools are configured
    #  enabled = 1
    #  locklist = <list file>
    # we can assume it is already installed
    def configure_version_locking
      config = versionlock_config
      config += "\n" unless config[-1] == "\n"
      enabled_re = /^\s*enabled\s*=.*$/
      if enabled_re.match(config)
        config = config.gsub(enabled_re, 'enabled = 1')
      else
        config += "enabled = 1\n"
      end
      unless config =~ /^\s*locklist\s*=.*$/
        config += "locklist = #{VERSIONLOCK_DEFAULT_LIST_FILE}\n"
      end
      File.open(versionlock_config_file, 'w') { |file| file.puts config }
      FileUtils.touch(versionlock_file)
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

    def clean_cache
      yum_action('clean', 'all')
    end

    def files_not_owned_by_package(directory)
      find_cmd = "find #{directory} -exec /bin/sh -c 'rpm -qf {} &> /dev/null || echo {}' \\;"
      sys.execute(find_cmd).split("\n")
    end

    private

    def versionlock_config
      File.exist?(versionlock_config_file) ? File.read(versionlock_config_file) : ''
    end

    def versionlock_config_file
      VERSIONLOCK_CONFIG_FILE
    end

    def versionlock_file
      result = versionlock_config.match(/^\s*locklist\s*=\s*(\S+)/)
      result.nil? ? nil : File.expand_path(result.captures[0])
    end

    def yum_action(action, packages, assumeyes: false)
      yum_options = []
      packages = [packages].flatten(1)
      yum_options << '-y' if assumeyes
      yum_options_s = yum_options.empty? ? '' : ' ' + yum_options.join(' ')
      packages_s = packages.empty? ? '' : ' ' + packages.join(' ')
      sys.execute!("yum#{yum_options_s} #{action}#{packages_s}",
                   :interactive => true)
    end
  end
end
