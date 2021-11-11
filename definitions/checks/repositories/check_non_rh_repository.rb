module Checks::Repositories
  class CheckNonRhRepository < ForemanMaintain::Check
    metadata do
      label :check_non_redhat_repository
      description 'Check whether system has any non Red Hat repositories (e.g.: EPEL) enabled'
      tags :pre_upgrade
      confine do
        feature(:instance).downstream
      end
    end

    def run
      with_spinner('Checking repositories enabled on the system') do
        assert(epel_not_enabled?, 'System is subscribed to non Red Hat repositories')
      end
    end

    def epel_not_enabled?
      system_repos = repos_manager.enabled_repos_hash
      system_repos.each do |repoid, repourl|
        if repoid.match?(/\bepel\b/i) || repourl.match?(/\bepel\b/i)
          return false
        end
      end
      true
    end
  end
end
