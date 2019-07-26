class Checks::CheckEpelRepository < ForemanMaintain::Check
  metadata do
    label :check_epel_repository
    description 'Check if EPEL repository enabled on system'
    tags :pre_upgrade
    confine do
      feature(:instance).downstream
    end
  end

  def run
    with_spinner('Checking for presence of EPEL repository') do
      assert(!epel_enabled?, 'System is subscribed to EPEL repository')
    end
  end

  def epel_enabled?
    system_repos = execute("yum repolist enabled -d 6 -e 0| grep -E 'Repo-baseurl|Repo-id'")
    system_repos.to_s.match(/\bepel\b/i)
  end
end
