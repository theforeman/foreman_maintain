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
        assert(!epel_enabled?, 'System is subscribed to non Red Hat repositories')
      end
    end

    def epel_enabled?
      system_repos = execute("yum repolist enabled -d 6 -e 0| grep -E 'Repo-baseurl|Repo-id'")
      system_repos.to_s.match(/\bepel\b/i)
    end
  end
end
