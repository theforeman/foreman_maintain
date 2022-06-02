module ForemanMaintain::PackageManager
  class Apt < Base
    def installed?(packages)
      packages_list = [packages].flatten(1).map { |pkg| "'#{pkg}'" }.join(' ')
      status, output = sys.execute_with_status(%(dpkg --status #{packages_list}))
      return false if status != 0

      status_of_pkg = output.split("\n").grep(/^Status:/).first
      if status_of_pkg.include?('installed')
        return true
      end

      false
    end

    def install(packages, assumeyes: false)
      apt_action('install', packages, :assumeyes => assumeyes)
    end

    def remove(packages, assumeyes: false)
      apt_action('remove', packages, :assumeyes => assumeyes)
    end

    def update(packages = [], assumeyes: false)
      action = packages.any? ? '--only-upgrade install' : 'upgrade'
      apt_action(action, packages, :assumeyes => assumeyes)
    end

    def clean_cache(assumeyes: false)
      apt_action('clean', :assumeyes => assumeyes)
    end

    def find_installed_package(name, queryfm = '')
      return unless installed?(name)

      dpkg_cmd = "dpkg-query --show #{name}"
      unless queryfm.empty?
        dpkg_cmd = "dpkg-query --showformat='#{queryfm}' --show #{name}"
      end
      _, result = sys.execute_with_status(dpkg_cmd)
      result
    end

    def check_update(packages: nil, with_status: false)
      apt_action('upgrade --dry-run', packages, :with_status => with_status)
    end

    def list_installed_packages(queryfm = '${binary:Package}-${VERSION}\n')
      # The queryfm should only include valid tag(s) as per `dpkg-query` man page.
      # If any special formatting is required with querytag then it should be provided with tag i.e,
      # querytag = "--%{VERSION}"
      # The queryfm string must end with '\n'
      sys.execute!("dpkg-query --showformat='#{queryfm}' -W").split("\n")
    end

    def version_locking_supported?
      false
    end

    def apt_action(action, packages, with_status: false, assumeyes: false, valid_exit_statuses: [0])
      apt_options = []
      packages = [packages].flatten(1)
      apt_options << '-y' if assumeyes
      apt_options_s = apt_options.empty? ? '' : ' ' + apt_options.join(' ')
      packages_s = packages.empty? ? '' : ' ' + packages.join(' ')
      if with_status
        sys.execute_with_status("apt-get#{apt_options_s} #{action}#{packages_s}",
                                :interactive => !assumeyes)
      else
        sys.execute!("apt-get#{apt_options_s} #{action}#{packages_s}",
                     :interactive => !assumeyes, :valid_exit_statuses => valid_exit_statuses)
      end
    end
  end
end
