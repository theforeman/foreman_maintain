module ForemanMaintain::RepositoryManager
  class El
    include ForemanMaintain::Concerns::OsFacts
    include ForemanMaintain::Concerns::SystemHelpers

    def disable_repos(repo_ids)
      if el7?
        execute!("yum-config-manager --disable #{repo_ids.join(',')}")
      else
        execute!("dnf config-manager --set-disabled #{repo_ids.join(',')}")
      end
    end

    def enable_repos(repo_ids)
      if el7?
        execute!("yum-config-manager --enable #{repo_ids.join(',')}")
      else
        execute!("dnf config-manager --set-enabled #{repo_ids.join(',')}")
      end
    end

    def enabled_repos_hash
      yum_cmd = 'yum repolist enabled -d 6 -e 0 2> /dev/null'
      repos = execute(yum_cmd)
      return {} if repos.empty?

      repo_hash = Hash[*repos.delete!(' ').split("\n").grep(/Repo-id|Repo-baseurl/)]
      trim_repos(repo_hash)
    end

    private

    def trim_repos(repo_hash)
      trimmed_repos = {}
      repo_hash.each do |repoid, repourl|
        trimmed_id = repoid.gsub(%r{Repo-id:|\/+\w*}, '')
        trimmed_url = repourl.gsub(/(^Repo-baseurl:)(.*)/, '\2')
        trimmed_repos[trimmed_id] = trimmed_url
      end
      trimmed_repos
    end
  end
end
