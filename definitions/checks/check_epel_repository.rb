class Checks::CheckEpelRepository < ForemanMaintain::Check
  metadata do
    label :check_epel_repository
    description 'Check to verify no any non Red Hat repositories(Eg: EPEL) enabled'
    tags :pre_upgrade
    confine do
      feature(:instance).downstream
    end
  end

  def run
    with_spinner('Checking if any non Red Hat repositories(Eg: EPEL) enabled on the system') do
      assert(!epel_enabled?, 'System is subscribed to non Red Hat repositories(Eg: EPEL)')
    end
  end

  def epel_enabled?
    system_repos = execute("yum repolist enabled -d 6 -e 0| grep -E 'Repo-baseurl|Repo-id'")
    system_repos.to_s.match(/\bepel\b/i)
  end
end
