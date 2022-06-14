module ForemanMaintain::RepositoryManager
  class Apt
    include ForemanMaintain::Concerns::SystemHelpers

    def disable_repos(repo_ids)
      repo_ids.each do |repo|
        execute!("apt-add-repository --remove #{repo}")
      end
    end

    def enable_repos(repo_ids)
      repo_ids.each do |repo|
        execute("apt-add-repository #{repo}")
      end
    end
  end
end
