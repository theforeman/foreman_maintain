module Procedures::Repositories
  class BackupEnabledRepos < ForemanMaintain::Procedure
    metadata do
      label :backup_enabled_repos
      description 'Stores enabled repositories in yaml file'
    end

    def run
      enabled_repos_ids = repository_manager.enabled_repos.keys
      unless enabled_repos_ids.empty?
        backup_dir = File.expand_path(ForemanMaintain.config.backup_dir)
        File.write(File.join(backup_dir, 'enabled_repos.yml'), enabled_repos_ids.to_yaml)
      end
    end
  end
end
