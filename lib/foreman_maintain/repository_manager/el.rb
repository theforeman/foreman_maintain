module ForemanMaintain::RepositoryManager
  class El
    include ForemanMaintain::Concerns::OsFacts
    include ForemanMaintain::Concerns::SystemHelpers

    def disable_repos(repo_ids)
      if el7?
        execute!("yum-config-manager #{config_manager_options(repo_ids, 'disable')}")
      else
        execute!("dnf config-manager #{config_manager_options(repo_ids, 'set-disabled')}")
      end
    end

    def rhsm_disable_repos(repo_ids)
      if rhsm_available?
        execute!(%(subscription-manager repos #{rhsm_options(repo_ids, 'disable')}))
      else
        logger.info("subscription-manager is not available.\
                     Using #{pkg_manager} config manager instead.")
        disable_repos(repo_ids)
      end
    end

    def enable_repos(repo_ids)
      if el7?
        execute!("yum-config-manager #{config_manager_options(repo_ids, 'enable')}")
      else
        execute!("dnf config-manager #{config_manager_options(repo_ids, 'enable')}")
      end
    end

    def rhsm_enable_repos(repo_ids)
      if rhsm_available?
        execute!(%(subscription-manager repos #{rhsm_options(repo_ids, 'enable')}))
      else
        logger.info("subscription-manager is not available.\
                     Using #{pkg_manager} config manager instead.")
        enable_repos(repo_ids)
      end
    end

    def rhsm_options(repo_ids, option)
      repo_ids.map { |r| "--#{option}=#{r}" }.join(' ')
    end

    def config_manager_options(repo_ids, option)
      if repo_ids.is_a?(String)
        if repo_ids == '*'
          return format_shell_args("--#{option}" => repo_ids.to_s)
        end

        "--#{option}=#{repo_ids}"
      elsif repo_ids.is_a?(Array)
        "--#{option} #{repo_ids.join(',')}"
      end
    end

    def rhsm_available?
      @rhsm_available ||= find_package('subscription-manager')
    end

    def rhsm_list_all_repos
      repos = execute(%(LANG=en_US.utf-8 subscription-manager repos --list 2>&1))
      return {} if repos.empty?

      hash_of_repoids_urls(repos, /Repo ID|Repo URL/)
    end

    def pkg_manager
      package_manager.class.name.split('::').last.downcase
    end

    def enabled_repos
      cmd = "#{pkg_manager} repolist enabled -d 6 -e 0 2> /dev/null"
      repos = execute(cmd)
      return {} if repos.empty?

      hash_of_repoids_urls(repos, /Repo-id|Repo-baseurl/)
    end

    def hash_of_repoids_urls(repos, regex)
      Hash[*repos.split("\n").grep(regex).map do |entry|
             entry.split(':', 2).last.strip
           end
      ]
    end
  end
end
