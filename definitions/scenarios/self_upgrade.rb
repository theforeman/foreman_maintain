module ForemanMaintain::Scenarios
  class SelfUpgradeBase < ForemanMaintain::Scenario
    include ForemanMaintain::Concerns::Downstream
    include ForemanMaintain::Concerns::Versions

    def target_version
      @target_version ||= begin
        v = Gem::Version.new(feature(:instance).target_version)
        "#{v.segments[0]}.#{v.segments[1] + 1}"
      end
    end

    def current_version
      feature(:instance).current_version
    end

    def maintenance_repo_label
      @maintenance_repo_label ||= context.get(:maintenance_repo_label)
    end

    def maintenance_repo_id(version)
      if maintenance_repo_label
        return maintenance_repo_label
      elsif (repo = ENV['MAINTENANCE_REPO_LABEL'])
        return repo unless repo.empty?
      end

      maintenance_repo(version)
    end

    def maintenance_repo(version)
      "satellite-maintenance-#{version}-for-rhel-#{el_major_version}-x86_64-rpms"
    end

    def use_rhsm?
      return false if maintenance_repo_label

      if (repo = ENV['MAINTENANCE_REPO_LABEL']) && !repo.empty?
        return false
      end

      true
    end

    def maintain_version
      @maintain_version ||= feature(:instance).target_version
    end

    def current_major
      Gem::Version.new(current_version).segments[0..1].join('.')
    end

    def upgrade_repo_version
      Gem::Version.new(current_version).bump.segments[0..1].join('.')
    end

    def req_repos_to_update_pkgs
      version = upgrade_repo_version
      if use_rhsm?
        main_rh_repos + [maintenance_repo_id(version)]
      else
        [maintenance_repo_id(version)]
      end
    end

    def self_upgrade_allowed?
      current_major == maintain_version ||
        Gem::Version.new(current_version).bump.segments[0..1].join('.') == maintain_version
    end
  end

  class SelfUpgrade < SelfUpgradeBase
    metadata do
      label :self_upgrade_foreman_maintain
      description "Enables the specified version's maintenance repository and,"\
                  "\nupdates the satellite-maintain packages"
      manual_detection
    end

    def downstream_self_upgrade(pkgs_to_update)
      unless self_upgrade_allowed?
        raise(
          ForemanMaintain::Error::Warn,
          "foreman-maintain does not support the installed version of Satellite." \
          "The currently installed version in #{current_version}," \
          "while foreman-maintain only supports #{maintain_version}." \
          "Please install the right version of foreman-maintain."
        )
      end

      add_step(Procedures::Packages::Update.new(packages: pkgs_to_update, assumeyes: true,
        enabled_repos: req_repos_to_update_pkgs))
    end

    def upstream_self_upgrade(pkgs_to_update)
      # This method is responsible for
      # 1. Setup the repositories of next major version
      # 2. Update the foreman-maintain packages from next major version repository
      # 3. Rollback the repository to current major version

      add_step(Procedures::Repositories::Setup.new(:version => target_version))
      add_step(Procedures::Packages::Update.new(packages: pkgs_to_update, assumeyes: true))
    ensure
      rollback_repositories
    end

    def rollback_repositories
      installed_release_pkg = package_manager.find_installed_package('foreman-release',
        '%{VERSION}')

      unless current_version.nil? && installed_release_pkg.nil?
        current_major_version = current_version[0..2]
        installed_foreman_release_major_version = installed_release_pkg[0..2]
        if installed_foreman_release_major_version != current_major_version
          add_step(Procedures::Packages::Uninstall.new(packages: %w[foreman-release katello-repos],
            assumeyes: true))
          add_step(Procedures::Repositories::Setup.new(:version => current_major_version))
        end
      end
    end

    def compose
      pkgs_to_update = [ForemanMaintain.main_package_name]
      if feature(:instance).downstream
        pkgs_to_update << 'satellite-maintain'
        downstream_self_upgrade(pkgs_to_update)
      elsif feature(:instance).upstream_install
        upstream_self_upgrade(pkgs_to_update)
      end
    end
  end
end
