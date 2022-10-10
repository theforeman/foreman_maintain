class Checks::CheckUpstreamRepository < ForemanMaintain::Check
  include ForemanMaintain::Concerns::Upstream

  metadata do
    label :check_upstream_repository
    description 'Check if any upstream repositories are enabled on system'
    tags :pre_upgrade
    preparation_steps do
      [Checks::Repositories::CheckNonRhRepository.new,
       Procedures::Packages::Install.new(:packages => %w[yum-utils])]
    end
    confine do
      feature(:instance).downstream
    end
  end

  def run
    with_spinner('Checking for presence of upstream repositories') do
      enabled_repo_ids = repoids_and_urls.keys
      assert(enabled_repo_ids.empty?,
        "System has upstream #{enabled_repo_ids.join(',')} repositories enabled",
        :next_steps => Procedures::Repositories::Disable.new(:repos => enabled_repo_ids))
    end
  end
end
