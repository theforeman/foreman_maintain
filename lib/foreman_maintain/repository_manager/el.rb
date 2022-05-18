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

    def rhsm_options(repo_ids, options)
      repo_ids.map { |r| "--#{options}=#{r}" }.join(' ')
    end

    def config_manager_options(repo_ids, options)
      repo_ids_string = if repo_ids.is_a?(Array)
                          repo_ids.join(',')
                        else
                          repo_ids
                        end
      format_shell_args("--#{options}" => repo_ids_string)
    end

    def rhsm_available?
      @rhsm_available ||= find_package('subscription-manager')
    end

    def rhsm_list_repos(list_option = '--list')
      repos = execute(%(LANG=en_US.utf-8 subscription-manager repos #{list_option} 2>&1))
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
      ids_urls = Hash[*repos.split("\n").grep(regex).map do |entry|
                        entry.split(':', 2).last.strip
                      end]

      # The EL7 yum repolist output includes extra info in the output,
      # as example
      # rhel-7-server-rpms/7Server/x86_64
      # rhel-server-rhscl-7-rpms/7Server/x86_64
      # This trims anything after first '/' to get correct repo label
      trimmed_hash = {}
      ids_urls.each do |id, url|
        trimmed_id = id.split('/').first
        trimmed_hash[trimmed_id] = url
      end
      trimmed_hash
    end
  end
end
