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
      enabled_upstream_repos = run_compare
      repos_to_disable = comma_separated_repositories(enabled_upstream_repos)
      assert(enabled_upstream_repos.empty?,
             "System has upstream #{repos_to_disable} repositories enabled",
             :next_steps => Procedures::Repositories::Disable.new(:repos => repos_to_disable))
    end
  end

  def comma_separated_repositories(repos)
    repos.map! { |r| r.gsub(%r{Repo-id:|\/+\w*}, '') }.join(',')
  end

  def run_compare
    enabled_upstream_repos = []
    repo_id = ''
    system_repos.each do |repo|
      repo_id = repo if repo =~ /Repo-id/
      next unless repo =~ /Repo-baseurl/

      upstream_repo.each do |regex|
        enabled_upstream_repos.push(repo_id) if repo =~ regex
      end
    end
    return enabled_upstream_repos
  end

  def system_repos
    repos = execute("yum repolist enabled -d 6 -e 0 2> /dev/null | grep -E 'Repo-id|Repo-baseurl'")
    return [] if repos.empty?

    repos.delete!(' ').split("\n")
  end

  def upstream_repo
    repo_urls = { :Foreman => %r{yum.theforeman.org\/},
                  :Katello => %r{fedorapeople.org\/groups\/katello\/releases\/yum\/[\/|\w|.]*} }
    [/#{repo_urls[:Foreman]}+releases/,
     /#{repo_urls[:Foreman]}+plugins/,
     /#{repo_urls[:Katello]}+katello/,
     /#{repo_urls[:Katello]}+client/,
     /#{repo_urls[:Katello]}+candlepin/,
     /#{repo_urls[:Katello]}+pulp/,
     %r{yum.puppetlabs.com\/el\/[\/|\w|.]*}]
  end
end
