class Checks::CheckUpstreamRepository < ForemanMaintain::Check
  metadata do
    label :check_upstream_repository
    description 'Check if any upstream repositories are enabled on system'
    tags :pre_upgrade
    preparation_steps do
      Procedures::Packages::Install.new(:packages => %w[yum-utils])
    end
    confine do
      feature(:downstream)
    end
  end

  def run
    with_spinner('Checking for presence of upstream repositories') do
      enabled_upstream_repos = feature(:system_repos).upstream_repos_id
      assert(enabled_upstream_repos.empty?,
             "System has upstream #{enabled_upstream_repos} repositories enabled",
             :next_steps => Procedures::Repositories::Disable.new(:repos => enabled_upstream_repos))
    end
  end
end
