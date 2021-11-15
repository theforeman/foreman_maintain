module ForemanMaintain::ReposManager
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
      yum_cmd = 'yum repolist enabled -d 6 -e 0 2> /dev/null'\
                "| grep -E 'Repo-id|Repo-baseurl'"
      repos = execute(yum_cmd)
      return {} if repos.empty?

      Hash[*repos.delete!(' ').split("\n")]
    end

    def trim_repoids(repos)
      repos.map { |r| r.gsub(%r{Repo-id:|\/+\w*}, '') }
    end
  end
end
