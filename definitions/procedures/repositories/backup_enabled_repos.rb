module Procedures::Repositories
  class BackupEnabledRepos < ForemanMaintain::Procedure
    metadata do
      label :backup_enabled_repos
      description 'Stores enabled repositories in yaml file'
    end

    def run
      enabled_repos_ids = feature(:system_repos).enabled_repos_ids
      backup_dir = File.expand_path(ForemanMaintain.config.backup_dir)
      unless enabled_repos_ids.empty?
        File.open(File.join(backup_dir, 'enabled_repos.yml'), 'w') do |repos_file|
          repos_file.puts enabled_repos_ids.to_yaml
        end
      end
    end
  end
end
