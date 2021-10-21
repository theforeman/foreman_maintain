module ForemanMaintain::Scenarios
  class SelfUpgradeBase < ForemanMaintain::Scenario
    def enabled_system_repos_id
      feature(:system_repos).enabled_repos_ids
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

    def maintenance_repo(version)
      "rhel-#{el_major_version}-server-satellite-maintenance-#{version}-rpms"
    end

    # Need to remove this before merging
    def skip_repo_enablement?
      !!context.get(:skip_repo_enablement)
    end

    def stored_enabled_repos_ids
      unless defined?(@stored_enabled_repos_ids)
        @stored_enabled_repos_ids = []
        path = File.expand_path('enabled_repos.yml', ForemanMaintain.config.backup_dir)
        @stored_enabled_repos_ids = File.file?(path) ? YAML.load(File.read(path)) : []
      end
      @stored_enabled_repos_ids
    end

    def all_maintenance_repos
      search_id = "rhel-#{el_major_version}-server-satellite-maintenance-"
      all_maintenance_repos = []
      stored_enabled_repos_ids.each do |id|
        next unless id.start_with?(search_id)
        all_maintenance_repos << id
      end
      all_maintenance_repos
    end

    def repos_ids_to_reenable
      repos_ids_to_reenable = stored_enabled_repos_ids - all_maintenance_repos
      repos_ids_to_reenable << if current_version == '6.10'
                                 maintenance_repo(6)
                               else
                                 maintenance_repo(current_version)
                               end
      repos_ids_to_reenable
    end
  end

  class SelfUpgrade < SelfUpgradeBase
    metadata do
      label :self_upgrade_foreman_maintain
      description "Enables the specified version's maintenance repository and, "\
  								'updates the foreman-maintain packages'
      manual_detection
    end

    def compose
      pkgs_to_update = %w[satellite-maintain rubygem-foreman_maintain]
      add_step(Procedures::Repositories::BackupEnabledRepos.new)
      disable_repos
      # Need to remove this before merging
      unless skip_repo_enablement?
        add_step(Procedures::Repositories::Enable.new(repos: [maintenance_repo(target_version)]))
      end
      add_step(Procedures::Packages::Update.new(packages: pkgs_to_update, assumeyes: true))
      enable_repos(repos_ids_to_reenable)
    end
  end

  class SelfUpgradeRescue < SelfUpgradeBase
    metadata do
      label :rescue_self_upgrade
      description 'Disables all version specific maintenance repo and,'\
  		' enables the repositories which were configured prior to self upgrade'
      manual_detection
      run_strategy :fail_slow
    end

    def compose
      enable_repos(repos_ids_to_reenable)
    end
  end
end
