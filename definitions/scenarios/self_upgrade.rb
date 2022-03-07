module ForemanMaintain::Scenarios
  class SelfUpgradeBase < ForemanMaintain::Scenario
    def enabled_system_repos_id
      repository_manager.enabled_repos.keys
    end

    def enable_repos(repo_ids = stored_enabled_repos_ids)
      add_step(Procedures::Repositories::Enable.new(repos: repo_ids))
    end

    def disable_repos(repo_ids = stored_enabled_repos_ids)
      add_step(Procedures::Repositories::Disable.new(repos: repo_ids))
    end

    def target_version
      @target_version ||= context.get(:target_version)
    end

    def current_version
      feature(:instance).downstream.current_minor_version
    end

    def maintenance_repo_id(version)
      if (repo = ENV['maintenance_repo'])
        return repo unless repo.empty?
      end

      maintenance_repo(version)
    end

    def maintenance_repo(version)
      if el7?
        "rhel-#{el_major_version}-server-satellite-maintenance-#{version}-rpms"
      else
        "satellite-maintenance-#{version}-for-rhel-#{el_major_version}-x86_64-rpms"
      end
    end

    def maintenance_repo_version
      return '6' if current_version == '6.10'

      current_version
    end

    def stored_enabled_repos_ids
      @stored_enabled_repos_ids ||= begin
        path = File.expand_path('enabled_repos.yml', ForemanMaintain.config.backup_dir)
        @stored_enabled_repos_ids = File.file?(path) ? YAML.load(File.read(path)) : []
      end
    end

    def all_maintenance_repos
      repo_regex = if el7?
                     /rhel-\d-server-satellite-maintenance-\d.\d-rpms/
                   else
                     /satellite-maintenance-\d.\d-for-rhel-\d-x86_64-rpms/
                   end
      stored_enabled_repos_ids.select { |id| !id.match(repo_regex).nil? }
    end

    def repos_ids_to_reenable
      repos_ids_to_reenable = stored_enabled_repos_ids - all_maintenance_repos
      repos_ids_to_reenable << maintenance_repo(maintenance_repo_version)
    end

    def use_rhsm?
      if (repo = ENV['maintenance_repo'])
        return false unless repo.empty?
      end

      true
    end
  end

  class SelfUpgrade < SelfUpgradeBase
    metadata do
      label :self_upgrade_foreman_maintain
      description "Enables the specified version's maintenance repository and,"\
  								"\nupdates the satellite-maintain packages"
      manual_detection
    end

    def compose
      if check_min_version('foreman', '2.5') || check_min_version('foreman-proxy', '2.5')
        pkgs_to_update = %w[satellite-maintain rubygem-foreman_maintain]
        add_step(Procedures::Repositories::BackupEnabledRepos.new)
        disable_repos
        add_step(Procedures::Repositories::Enable.new(repos: [maintenance_repo_id(target_version)],
                                                      use_rhsm: use_rhsm?))
        add_step(Procedures::Packages::Update.new(packages: pkgs_to_update, assumeyes: true))
        enable_repos(repos_ids_to_reenable)
      end
    end
  end

  class SelfUpgradeRescue < SelfUpgradeBase
    metadata do
      label :rescue_self_upgrade
      description 'Disables all version specific maintenance repositories and,'\
  		 "\nenables the repositories which were configured prior to self upgrade"
      manual_detection
      run_strategy :fail_slow
    end

    def compose
      if check_min_version('foreman', '2.5') || check_min_version('foreman-proxy', '2.5')
        enable_repos(repos_ids_to_reenable)
      end
    end
  end
end
