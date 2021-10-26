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

    def maintenance_repo_id(version)
      return ENV['maintenance_repo'] unless ENV['maintenance_repo'].empty?

      maintenance_repo(version)
    end

    def maintenance_repo(version)
      "rhel-#{el_major_version}-server-satellite-maintenance-#{version}-rpms"
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
      repo_prefix = "rhel-#{el_major_version}-server-satellite-maintenance-"
      stored_enabled_repos_ids.select { |id| id.start_with?(repo_prefix) }
    end

    def repos_ids_to_reenable
      repos_ids_to_reenable = stored_enabled_repos_ids - all_maintenance_repos
      repos_ids_to_reenable << maintenance_repo(maintenance_repo_version)
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
      add_step(Procedures::Repositories::Enable.new(repos: [maintenance_repo_id(target_version)]))
      add_step(Procedures::Packages::Update.new(packages: pkgs_to_update, assumeyes: true))
      enable_repos(repos_ids_to_reenable)
    end
  end

  class SelfUpgradeRescue < SelfUpgradeBase
    metadata do
      label :rescue_self_upgrade
      description 'Disables all version specific maintenance repos and,'\
  		' enables the repositories which were configured prior to self upgrade'
      manual_detection
      run_strategy :fail_slow
    end

    def compose
      enable_repos(repos_ids_to_reenable)
    end
  end
end
